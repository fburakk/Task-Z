using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using CleanArchitecture.Core.Entities;
using CleanArchitecture.Infrastructure.Contexts;
using CleanArchitecture.Infrastructure.Models;
using CleanArchitecture.WebApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace CleanArchitecture.WebApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class AiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ITaskClassificationService _taskClassificationService;
        private readonly int _recentTasksLimit;

        public AiController(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager,
            ITaskClassificationService taskClassificationService,
            IConfiguration configuration)
        {
            _context = context;
            _userManager = userManager;
            _taskClassificationService = taskClassificationService;
            _recentTasksLimit = int.TryParse(configuration["AiSettings:RecentTasksLimit"], out var limit) ? limit : 5;
        }

        [HttpPost("suggest-assignee")]
        public async Task<ActionResult<SuggestAssigneeResponse>> SuggestAssignee(SuggestAssigneeRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("uid")?.Value;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            if (string.IsNullOrWhiteSpace(request?.Title))
            {
                return BadRequest("Task title is required.");
            }

            var board = await _context.Boards
                .Include(b => b.Workspace)
                .Include(b => b.Users)
                .AsNoTracking()
                .FirstOrDefaultAsync(b => b.Id == request.BoardId &&
                    (b.Workspace.UserId == userId ||
                     b.Users.Any(u => u.UserId == userId)));

            if (board == null)
                return NotFound("Board not found or access denied.");

            var memberUserIds = board.Users.Select(u => u.UserId).Distinct().ToList();
            if (!memberUserIds.Contains(board.Workspace.UserId))
            {
                memberUserIds.Add(board.Workspace.UserId);
            }

            if (!memberUserIds.Any())
                return BadRequest("Board has no members.");

            string taskCategory;
            double taskCategoryConfidence;
            if (!string.IsNullOrWhiteSpace(request.WorkCategory))
            {
                taskCategory = TaskCategoryHelper.Normalize(request.WorkCategory);
                taskCategoryConfidence = 1;
            }
            else
            {
                var classification = await _taskClassificationService.ClassifyAsync(request.Title, request.Description);
                taskCategory = TaskCategoryHelper.Normalize(classification.Category);
                taskCategoryConfidence = classification.Confidence;
            }

            var now = DateTime.UtcNow;
            var openTaskStats = await _context.BoardTasks
                .Where(t => t.BoardId == request.BoardId &&
                            t.AssigneeId != null &&
                            memberUserIds.Contains(t.AssigneeId) &&
                            t.Status.Type != BoardStatus.Done)
                .GroupBy(t => t.AssigneeId)
                .Select(e => new
                {
                    UserId = e.Key,
                    ActiveTasks = e.Count(),
                    OverdueTasks = e.Count(t => t.DueDate.HasValue && t.DueDate.Value < now)
                })
                .ToDictionaryAsync(x => x.UserId, x => new { x.ActiveTasks, x.OverdueTasks });

            var members = await _userManager.Users
                .Where(u => memberUserIds.Contains(u.Id))
                .Select(u => new { u.Id, u.UserName, u.FirstName, u.LastName })
                .ToListAsync();

            var memberRole = board.Users.ToDictionary(u => u.UserId, u => u.Role);
            var categoryScores = await _context.UserCategoryScores
                .AsNoTracking()
                .Where(x => memberUserIds.Contains(x.UserId) && x.Category == taskCategory)
                .ToDictionaryAsync(x => x.UserId, x => x);

            var candidateScores = members.Select(m =>
            {
                openTaskStats.TryGetValue(m.Id, out var taskStat);
                categoryScores.TryGetValue(m.Id, out var categoryScore);

                var categoryCompletedTasks = categoryScore?.CompletedTasks ?? 0;
                var categoryScoreValue = Math.Round(categoryScore?.Score ?? 50, 2);
                var role = memberRole.TryGetValue(m.Id, out var resolvedRole) ? resolvedRole : "member";
                var activeTaskCount = taskStat?.ActiveTasks ?? 0;
                var overdueTaskCount = taskStat?.OverdueTasks ?? 0;

                // Fast score: category skill + lightweight workload penalties.
                var categoryWeight = categoryScoreValue / 100.0;
                var categoryExperience = Math.Min(categoryCompletedTasks, 10) / 10.0;
                var workloadPenalty = Math.Min(activeTaskCount, 8) / 8.0;
                var overduePenalty = Math.Min(overdueTaskCount, 5) / 5.0;
                var roleBonus = string.Equals(role, "owner", StringComparison.OrdinalIgnoreCase) ? 0.03 : 0;

                var finalScore = (categoryWeight * 70)
                    + (categoryExperience * 20)
                    + ((1 - workloadPenalty) * 7)
                    + ((1 - overduePenalty) * 3)
                    + (roleBonus * 100);
                finalScore = Math.Round(Math.Max(0, Math.Min(100, finalScore)), 2);

                return new SuggestedAssigneeCandidate
                {
                    UserId = m.Id,
                    Username = m.UserName,
                    FirstName = m.FirstName,
                    LastName = m.LastName,
                    Role = role,
                    Score = finalScore,
                    Category = taskCategory,
                    CategoryScore = categoryScoreValue,
                    CategoryCompletedTasks = categoryCompletedTasks,
                    ActiveTasks = activeTaskCount,
                    OverdueTasks = overdueTaskCount
                };
            }).ToList();

            var orderedCandidates = candidateScores
                .OrderByDescending(x => x.Score)
                .ThenBy(x => x.ActiveTasks)
                .ThenBy(x => x.OverdueTasks)
                .ToList();

            var recommendation = orderedCandidates.FirstOrDefault();
            return Ok(new SuggestAssigneeResponse
            {
                RecommendedUserId = recommendation?.UserId,
                RecommendedUsername = recommendation?.Username,
                TaskCategory = taskCategory,
                TaskCategoryConfidence = Math.Round(taskCategoryConfidence, 3),
                GeneratedAt = now,
                Candidates = orderedCandidates
            });
        }

        [HttpPost("assigned-task-assistant-context")]
        public async Task<ActionResult<AssignedTaskAssistantContextResponse>> GetAssignedTaskAssistantContext(AssignedTaskAssistantContextRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("uid")?.Value;

            var task = await _context.BoardTasks
                .Include(t => t.Board)
                .ThenInclude(b => b.Workspace)
                .Include(t => t.Board)
                .ThenInclude(b => b.Users)
                .Include(t => t.Status)
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.Id == request.TaskId &&
                    t.AssigneeId == userId);

            if (task == null)
                return NotFound("Assigned task not found or access denied.");

            var board = task.Board;
            var hasAccess = board.Workspace.UserId == userId || board.Users.Any(u => u.UserId == userId);

            if (!hasAccess)
                return NotFound("Assigned task not found or access denied.");

            var previousCompletedTasks = await _context.TaskEvents
                .Where(e => e.EventType == "Completed" &&
                            e.AssigneeId == userId &&
                            e.TaskId != request.TaskId)
                .OrderByDescending(e => e.Created)
                .Take(_recentTasksLimit)
                .Select(e => new
                {
                    e.Title,
                    e.Description,
                    e.Priority,
                    CompletedAt = e.Created,
                    e.AssignedAt
                })
                .ToListAsync();

            var completedDurations = await _context.TaskEvents
                .Where(e => e.EventType == "Completed" &&
                            e.AssigneeId == userId &&
                            e.AssignedAt != null)
                .Select(e => new
                {
                    Duration = (e.Created - e.AssignedAt.Value).TotalHours
                })
                .ToListAsync();

            var avgCompletionHours = completedDurations.Any()
                ? Math.Round(completedDurations.Average(x => x.Duration), 1)
                : 0.0;

            var currentOpenAssignedTasks = await _context.BoardTasks
                .Where(t => t.AssigneeId == userId &&
                            t.Status.Type != BoardStatus.Done)
                .CountAsync();

            var previousTaskDtos = previousCompletedTasks.Select(e => new UserCompletedTaskContextDto
            {
                Title = e.Title,
                Description = e.Description,
                Priority = e.Priority,
                CompletedAt = e.CompletedAt,
                CompletionHours = e.AssignedAt != null 
                    ? Math.Round((e.CompletedAt - e.AssignedAt.Value).TotalHours, 1)
                    : null
            }).ToList();

            var userHistory = new UserTaskHistoryContextDto
            {
                CompletedTasksTotal = await _context.TaskEvents
                    .Where(e => e.EventType == "Completed" && e.AssigneeId == userId)
                    .CountAsync(),
                AvgCompletionHours = avgCompletionHours,
                CurrentOpenAssignedTasks = currentOpenAssignedTasks,
                PreviousCompletedTasks = previousTaskDtos
            };

            var assignedTask = new AssignedTaskContextDto
            {
                TaskId = task.Id,
                Title = task.Title,
                Description = task.Description,
                Priority = task.Priority,
                DueDate = task.DueDate
            };

            var expectedResponseFormat = new AssignedTaskExpectedResponseFormatDto
            {
                Summary = "1-2 sentences",
                ActionPlan = new List<string> { "step-1", "step-2", "step-3" },
                RiskNotes = new List<string> { "risk-1", "risk-2" }
            };

            return Ok(new AssignedTaskAssistantContextResponse
            {
                Instruction = "You are a task coach AI assistant. Provide concise, actionable guidance on how the user can complete the assigned task better based on their past experience. Avoid unnecessary long explanations. Respond only in the specified JSON format.",
                ExpectedResponseFormat = expectedResponseFormat,
                AssignedTask = assignedTask,
                UserHistory = userHistory
            });
        }
    }

    public class SuggestAssigneeRequest
    {
        public int BoardId { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string WorkCategory { get; set; }
    }

    public class SuggestedAssigneeCandidate
    {
        public string UserId { get; set; }
        public string Username { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Role { get; set; }
        public double Score { get; set; }
        public string Category { get; set; }
        public double CategoryScore { get; set; }
        public int CategoryCompletedTasks { get; set; }
        public int ActiveTasks { get; set; }
        public int OverdueTasks { get; set; }
    }

    public class SuggestAssigneeResponse
    {
        public string RecommendedUserId { get; set; }
        public string RecommendedUsername { get; set; }
        public string TaskCategory { get; set; }
        public double TaskCategoryConfidence { get; set; }
        public DateTime GeneratedAt { get; set; }
        public List<SuggestedAssigneeCandidate> Candidates { get; set; } = new();
    }

    public class AssignedTaskAssistantContextRequest
    {
        public int TaskId { get; set; }
    }

    public class AssignedTaskExpectedResponseFormatDto
    {
        public string Summary { get; set; }
        public List<string> ActionPlan { get; set; }
        public List<string> RiskNotes { get; set; }
    }

    public class AssignedTaskContextDto
    {
        public int TaskId { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string Priority { get; set; }
        public DateTime? DueDate { get; set; }
    }

    public class UserCompletedTaskContextDto
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public string Priority { get; set; }
        public DateTime CompletedAt { get; set; }
        public double? CompletionHours { get; set; }
    }

    public class UserTaskHistoryContextDto
    {
        public int CompletedTasksTotal { get; set; }
        public double AvgCompletionHours { get; set; }
        public int CurrentOpenAssignedTasks { get; set; }
        public List<UserCompletedTaskContextDto> PreviousCompletedTasks { get; set; }
    }

    public class AssignedTaskAssistantContextResponse
    {
        public string Instruction { get; set; }
        public AssignedTaskExpectedResponseFormatDto ExpectedResponseFormat { get; set; }
        public AssignedTaskContextDto AssignedTask { get; set; }
        public UserTaskHistoryContextDto UserHistory { get; set; }
    }
}
