using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using CleanArchitecture.Core.Entities;
using CleanArchitecture.Infrastructure.Contexts;
using CleanArchitecture.Infrastructure.Models;
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
        private readonly int _recentTasksLimit;

        public AiController(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager,
            IConfiguration configuration)
        {
            _context = context;
            _userManager = userManager;
            _recentTasksLimit = int.TryParse(configuration["AiSettings:RecentTasksLimit"], out var limit) ? limit : 5;
        }

        [HttpPost("suggest-assignee")]
        public async Task<ActionResult<AssigneeContextResponse>> SuggestAssignee(SuggestAssigneeRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("uid")?.Value;

            var board = await _context.Boards
                .Include(b => b.Workspace)
                .Include(b => b.Users)
                .AsNoTracking()
                .FirstOrDefaultAsync(b => b.Id == request.BoardId &&
                    (b.Workspace.UserId == userId ||
                     b.Users.Any(u => u.UserId == userId)));

            if (board == null)
                return NotFound("Board not found or access denied.");

            var memberUserIds = board.Users.Select(u => u.UserId).ToList();

            if (!memberUserIds.Any())
                return BadRequest("Board has no members.");

            var openTaskCounts = await _context.BoardTasks
                .Where(t => t.BoardId == request.BoardId &&
                            t.AssigneeId != null &&
                            memberUserIds.Contains(t.AssigneeId))
                .GroupBy(t => t.AssigneeId)
                .Select(g => new { UserId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.UserId, x => x.Count);

            var completedEvents = await _context.TaskEvents
                .Where(e => e.BoardId == request.BoardId &&
                            e.EventType == "Completed" &&
                            e.AssigneeId != null &&
                            memberUserIds.Contains(e.AssigneeId))
                .Select(e => new
                {
                    e.AssigneeId,
                    e.Title,
                    e.Description,
                    e.AssignedAt,
                    CompletedAt = e.Created
                })
                .ToListAsync();

            var memberStats = completedEvents
                .GroupBy(e => e.AssigneeId)
                .ToDictionary(
                    g => g.Key,
                    g => new
                    {
                        CompletedCount = g.Count(),
                        AvgHours = g.Any(e => e.AssignedAt != null)
                            ? Math.Round(g.Where(e => e.AssignedAt != null)
                                .Average(e => (e.CompletedAt - e.AssignedAt.Value).TotalHours), 1)
                            : 0.0,
                        RecentTasks = g.OrderByDescending(e => e.CompletedAt)
                                        .Take(_recentTasksLimit)
                                        .Select(e => new CompletedTaskDto { Title = e.Title, Description = e.Description })
                                        .ToList()
                    });

            var members = await _userManager.Users
                .Where(u => memberUserIds.Contains(u.Id))
                .Select(u => new { u.Id, u.UserName, u.FirstName, u.LastName })
                .ToListAsync();

            var memberRole = board.Users.ToDictionary(u => u.UserId, u => u.Role);

            var memberDtos = members.Select(m =>
            {
                memberStats.TryGetValue(m.Id, out var stats);
                openTaskCounts.TryGetValue(m.Id, out var openCount);
                return new MemberContextDto
                {
                    Username = m.UserName,
                    FirstName = m.FirstName,
                    LastName = m.LastName,
                    Role = memberRole.TryGetValue(m.Id, out var role) ? role : "member",
                    CurrentOpenTasks = openCount,
                    CompletedTasksTotal = stats?.CompletedCount ?? 0,
                    AvgCompletionHours = stats?.AvgHours ?? 0,
                    RecentCompletedTasks = stats?.RecentTasks ?? new List<CompletedTaskDto>()
                };
            }).ToList();

            return Ok(new AssigneeContextResponse
            {
                Instruction = "Sen bir görev yönetim sistemi için çalışan bir yapay zeka asistanısın. Verilen göreve en uygun ekip üyesini öner.",
                ExpectedResponseFormat = new ExpectedResponseFormatDto
                {
                    RecommendedUsername = "string",
                    Reason = "kısa-açıklama"
                },
                Task = new TaskContextDto
                {
                    Title = request.Title,
                    Description = request.Description
                },
                Members = memberDtos
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
                Summary = "1-2 cümle",
                ActionPlan = new List<string> { "adım-1", "adım-2", "adım-3" },
                RiskNotes = new List<string> { "risk-1", "risk-2" }
            };

            return Ok(new AssignedTaskAssistantContextResponse
            {
                Instruction = "Sen bir görev koçu yapay zeka asistanısın. Kullanıcıya, kendisine atanmış görevi geçmiş tecrübesine göre nasıl daha iyi tamamlayabileceği konusunda kısa, net ve uygulanabilir öneriler ver. Gereksiz uzun açıklamalardan kaçın. Sadece belirtilen JSON formatında cevap ver.",
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
    }

    public class TaskContextDto
    {
        public string Title { get; set; }
        public string Description { get; set; }
    }

    public class MemberContextDto
    {
        public string Username { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Role { get; set; }
        public int CurrentOpenTasks { get; set; }
        public int CompletedTasksTotal { get; set; }
        public double AvgCompletionHours { get; set; }
        public List<CompletedTaskDto> RecentCompletedTasks { get; set; }
    }

    public class CompletedTaskDto
    {
        public string Title { get; set; }
        public string Description { get; set; }
    }

    public class AssigneeContextResponse
    {
        public string Instruction { get; set; }
        public ExpectedResponseFormatDto ExpectedResponseFormat { get; set; }
        public TaskContextDto Task { get; set; }
        public List<MemberContextDto> Members { get; set; }
    }

    public class ExpectedResponseFormatDto
    {
        public string RecommendedUsername { get; set; }
        public string Reason { get; set; }
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
