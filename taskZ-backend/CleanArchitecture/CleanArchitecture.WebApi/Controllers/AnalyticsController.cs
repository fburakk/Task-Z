using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using CleanArchitecture.Core.DTOs.Analytics;
using CleanArchitecture.Core.Entities;
using CleanArchitecture.Infrastructure.Contexts;
using CleanArchitecture.Infrastructure.Models;
using CleanArchitecture.WebApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CleanArchitecture.WebApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class AnalyticsController : ControllerBase
    {
        private static readonly HashSet<string> StopWords = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "and", "the", "for", "with", "that", "this", "from", "task", "todo"
        };
        private static readonly HashSet<string> CompletedStatusKeywords = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "done",
            "completed",
            "complete",
            "closed",
            "finish",
            "finished"
        };

        private static class TaskEventTypes
        {
            public const string Created = "Created";
            public const string Completed = "Completed";
        }

        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ITaskClassificationService _taskClassificationService;

        public AnalyticsController(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager,
            ITaskClassificationService taskClassificationService)
        {
            _context = context;
            _userManager = userManager;
            _taskClassificationService = taskClassificationService;
        }

        [HttpGet("overview")]
        public async Task<ActionResult<AnalyticsOverviewResponse>> GetOverview([FromQuery] AnalyticsQuery query)
        {
            var requesterId = GetCurrentUserId();
            if (string.IsNullOrWhiteSpace(requesterId))
            {
                return Unauthorized();
            }

            var boardIds = await GetAccessibleBoardIds(requesterId, query.WorkspaceId, query.BoardId);
            if (!boardIds.Any())
            {
                return new AnalyticsOverviewResponse { GeneratedAt = DateTime.UtcNow };
            }

            var currentTasks = await GetCurrentTaskRows(boardIds);
            var taskEvents = await GetTaskEvents(boardIds);

            var createdEvents = taskEvents.Where(e => e.EventType == TaskEventTypes.Created).ToList();
            var completedEvents = taskEvents.Where(e => e.EventType == TaskEventTypes.Completed).ToList();
            var latestCompletedByTaskId = completedEvents
                .GroupBy(e => e.TaskId)
                .ToDictionary(
                    g => g.Key,
                    g => g.OrderByDescending(x => x.Created).First());
            var completedCurrentTaskIds = currentTasks
                .Where(t => IsCompletedStatus(t.StatusType, t.StatusTitle))
                .Select(t => t.TaskId)
                .Distinct()
                .ToList();
            var completedCurrentTasks = completedCurrentTaskIds.Count;
            var completedCurrentEvents = completedCurrentTaskIds
                .Where(taskId => latestCompletedByTaskId.ContainsKey(taskId))
                .Select(taskId => latestCompletedByTaskId[taskId])
                .ToList();

            var completionDurations = CalculateCompletionDurations(createdEvents, completedCurrentEvents);
            var overview = new AnalyticsOverviewResponse
            {
                TotalTasks = currentTasks.Count,
                CompletedTasks = completedCurrentTasks,
                ActiveTasks = currentTasks.Count - completedCurrentTasks,
                OverdueTasks = currentTasks.Count(t => !IsCompletedStatus(t.StatusType, t.StatusTitle) && t.DueDate.HasValue && t.DueDate.Value < DateTime.UtcNow),
                CreatedInRange = currentTasks.Count(t => IsInRange(t.Created, query.From, query.To)),
                CompletedInRange = completedCurrentEvents.Count(e => IsInRange(e.Created, query.From, query.To)),
                CompletionRate = currentTasks.Count == 0 ? 0 : Math.Round((double)completedCurrentTasks / currentTasks.Count * 100, 2),
                AverageCompletionHours = completionDurations.Any() ? Math.Round(completionDurations.Average(), 2) : 0,
                GeneratedAt = DateTime.UtcNow
            };

            return overview;
        }

        [HttpGet("users")]
        public async Task<ActionResult<List<UserAnalyticsResponse>>> GetUserAnalytics([FromQuery] AnalyticsQuery query)
        {
            var requesterId = GetCurrentUserId();
            if (string.IsNullOrWhiteSpace(requesterId))
            {
                return Unauthorized();
            }

            var boardIds = await GetAccessibleBoardIds(requesterId, query.WorkspaceId, query.BoardId);
            if (!boardIds.Any())
            {
                return new List<UserAnalyticsResponse>();
            }

            var currentTasks = await GetCurrentTaskRows(boardIds);
            var taskEvents = await GetTaskEvents(boardIds);
            var createdEvents = taskEvents.Where(e => e.EventType == TaskEventTypes.Created).ToList();
            var completedEvents = taskEvents.Where(e => e.EventType == TaskEventTypes.Completed).ToList();
            var createdByTaskId = createdEvents
                .GroupBy(e => e.TaskId)
                .ToDictionary(g => g.Key, g => g.Min(x => x.Created));
            var latestCompletedByTaskId = completedEvents
                .GroupBy(e => e.TaskId)
                .ToDictionary(
                    g => g.Key,
                    g => g.OrderByDescending(x => x.Created).First());

            var boardMemberIds = await _context.BoardUsers
                .AsNoTracking()
                .Where(bu => boardIds.Contains(bu.BoardId))
                .Select(bu => bu.UserId)
                .Distinct()
                .ToListAsync();

            var userIds = boardMemberIds
                .Union(currentTasks.Where(t => !string.IsNullOrWhiteSpace(t.AssigneeId)).Select(t => t.AssigneeId))
                .Union(completedEvents.Where(e => !string.IsNullOrWhiteSpace(e.AssigneeId)).Select(e => e.AssigneeId))
                .Distinct()
                .ToList();

            var userLookup = await _userManager.Users
                .Where(u => userIds.Contains(u.Id))
                .Select(u => new { u.Id, u.UserName })
                .ToDictionaryAsync(u => u.Id, u => u.UserName);

            var response = new List<UserAnalyticsResponse>();
            foreach (var userId in userIds)
            {
                var assignedNow = currentTasks.Where(t => t.AssigneeId == userId).ToList();
                var activeNow = assignedNow.Where(t => !IsCompletedStatus(t.StatusType, t.StatusTitle)).ToList();
                var completedNowTaskIds = assignedNow
                    .Where(t => IsCompletedStatus(t.StatusType, t.StatusTitle))
                    .Select(t => t.TaskId)
                    .Distinct()
                    .ToList();
                var completedByUser = completedNowTaskIds
                    .Where(taskId => latestCompletedByTaskId.ContainsKey(taskId))
                    .Select(taskId => latestCompletedByTaskId[taskId])
                    .ToList();
                var completedTaskCount = completedNowTaskIds.Count;
                var completedInRange = completedByUser.Count(e => IsInRange(e.Created, query.From, query.To));

                var onTimeEvents = completedByUser.Where(e => e.DueDate.HasValue).ToList();
                var onTimeRate = onTimeEvents.Any()
                    ? (double)onTimeEvents.Count(e => e.Created <= e.DueDate.Value) / onTimeEvents.Count
                    : 0;

                var durations = completedByUser
                    .Where(e => createdByTaskId.ContainsKey(e.TaskId) && e.Created >= createdByTaskId[e.TaskId])
                    .Select(e => (e.Created - createdByTaskId[e.TaskId]).TotalHours)
                    .ToList();

                var completionRateDenominator = completedTaskCount + activeNow.Count;
                response.Add(new UserAnalyticsResponse
                {
                    UserId = userId,
                    Username = userLookup.ContainsKey(userId) ? userLookup[userId] : userId,
                    AssignedTasks = assignedNow.Count,
                    CompletedTasks = completedTaskCount,
                    ActiveTasks = activeNow.Count,
                    OverdueTasks = activeNow.Count(t => t.DueDate.HasValue && t.DueDate.Value < DateTime.UtcNow),
                    CompletedInRange = completedInRange,
                    CompletionRate = completionRateDenominator == 0 ? 0 : Math.Round((double)completedTaskCount / completionRateDenominator * 100, 2),
                    OnTimeRate = Math.Round(onTimeRate * 100, 2),
                    AverageCompletionHours = durations.Any() ? Math.Round(durations.Average(), 2) : 0
                });
            }

            return response
                .OrderByDescending(u => u.CompletedInRange)
                .ThenByDescending(u => u.CompletedTasks)
                .ToList();
        }

        [HttpGet("users/category-performance")]
        public async Task<ActionResult<List<UserCategoryPerformanceResponse>>> GetUserCategoryPerformance([FromQuery] AnalyticsQuery query)
        {
            var requesterId = GetCurrentUserId();
            if (string.IsNullOrWhiteSpace(requesterId))
            {
                return Unauthorized();
            }

            var boardIds = await GetAccessibleBoardIds(requesterId, query.WorkspaceId, query.BoardId);
            if (!boardIds.Any())
            {
                return new List<UserCategoryPerformanceResponse>();
            }

            var normalizedCategory = string.IsNullOrWhiteSpace(query.Category)
                ? null
                : TaskCategoryHelper.Normalize(query.Category);

            var completedTasks = await _context.BoardTasks
                .AsNoTracking()
                .Where(t => boardIds.Contains(t.BoardId) && t.AssigneeId != null)
                .Select(t => new CategoryPerformanceTaskRow
                {
                    TaskId = t.Id,
                    AssigneeId = t.AssigneeId,
                    WorkCategory = t.WorkCategory,
                    Priority = t.Priority,
                    DueDate = t.DueDate,
                    AssignedAt = t.AssignedAt,
                    Created = t.Created,
                    StatusType = t.Status.Type,
                    StatusTitle = t.Status.Title
                })
                .ToListAsync();

            var currentlyCompletedTasks = completedTasks
                .Where(t => IsCompletedStatus(t.StatusType, t.StatusTitle))
                .ToList();
            if (!string.IsNullOrWhiteSpace(normalizedCategory))
            {
                currentlyCompletedTasks = currentlyCompletedTasks
                    .Where(t => TaskCategoryHelper.Normalize(t.WorkCategory) == normalizedCategory)
                    .ToList();
            }

            if (!currentlyCompletedTasks.Any())
            {
                return new List<UserCategoryPerformanceResponse>();
            }

            var completedTaskIds = currentlyCompletedTasks
                .Select(t => t.TaskId)
                .Distinct()
                .ToList();
            var completedAtLookup = await _context.TaskEvents
                .AsNoTracking()
                .Where(e => e.EventType == TaskEventTypes.Completed && completedTaskIds.Contains(e.TaskId))
                .GroupBy(e => e.TaskId)
                .Select(g => new { TaskId = g.Key, CompletedAt = g.Max(x => x.Created) })
                .ToDictionaryAsync(x => x.TaskId, x => x.CompletedAt);

            var groupedScores = currentlyCompletedTasks
                .GroupBy(t => new
                {
                    UserId = t.AssigneeId,
                    Category = TaskCategoryHelper.Normalize(t.WorkCategory)
                })
                .Select(group =>
                {
                    var taskStats = group.Select(task =>
                    {
                        var completedAt = completedAtLookup.ContainsKey(task.TaskId)
                            ? completedAtLookup[task.TaskId]
                            : task.Created;
                        var effectiveStart = task.AssignedAt ?? task.Created;
                        var completionHours = Math.Max(0.1, (completedAt - effectiveStart).TotalHours);
                        var speedScore = CalculateTaskSpeedScore(completionHours, task.Priority);
                        var onTime = !task.DueDate.HasValue || completedAt <= task.DueDate.Value;

                        return new
                        {
                            CompletedAt = completedAt,
                            CompletionHours = completionHours,
                            SpeedScore = speedScore,
                            OnTime = onTime
                        };
                    }).ToList();

                    return new UserCategoryPerformanceResponse
                    {
                        UserId = group.Key.UserId,
                        Category = group.Key.Category,
                        CompletedTasks = taskStats.Count,
                        OnTimeRate = taskStats.Any()
                            ? Math.Round((double)taskStats.Count(x => x.OnTime) / taskStats.Count * 100, 2)
                            : 0,
                        AverageCompletionHours = taskStats.Any()
                            ? Math.Round(taskStats.Average(x => x.CompletionHours), 2)
                            : 0,
                        Score = taskStats.Any()
                            ? Math.Round(taskStats.Average(x => x.SpeedScore), 2)
                            : 0,
                        LastCompletedAt = taskStats.Any()
                            ? taskStats.Max(x => x.CompletedAt)
                            : null
                    };
                })
                .ToList();

            var userIds = groupedScores.Select(x => x.UserId).Distinct().ToList();
            var userLookup = await _userManager.Users
                .Where(u => userIds.Contains(u.Id))
                .Select(u => new { u.Id, u.UserName })
                .ToDictionaryAsync(u => u.Id, u => u.UserName);

            return groupedScores
                .Select(x =>
                {
                    x.Username = userLookup.ContainsKey(x.UserId) ? userLookup[x.UserId] : x.UserId;
                    return x;
                })
                .OrderBy(x => x.Category)
                .ThenByDescending(x => x.Score)
                .ToList();
        }

        [HttpGet("tasks/category-audit")]
        public async Task<ActionResult<List<TaskCategoryAuditResponse>>> GetTaskCategoryAudit([FromQuery] AnalyticsQuery query)
        {
            var requesterId = GetCurrentUserId();
            if (string.IsNullOrWhiteSpace(requesterId))
            {
                return Unauthorized();
            }

            var boardIds = await GetAccessibleBoardIds(requesterId, query.WorkspaceId, query.BoardId);
            if (!boardIds.Any())
            {
                return new List<TaskCategoryAuditResponse>();
            }

            var normalizedCategory = string.IsNullOrWhiteSpace(query.Category)
                ? null
                : TaskCategoryHelper.Normalize(query.Category);

            var taskQuery = _context.BoardTasks
                .AsNoTracking()
                .Where(t => boardIds.Contains(t.BoardId));

            if (!string.IsNullOrWhiteSpace(normalizedCategory))
            {
                taskQuery = taskQuery.Where(t => t.WorkCategory == normalizedCategory);
            }

            if (query.From.HasValue)
            {
                taskQuery = taskQuery.Where(t => t.Created >= query.From.Value);
            }

            if (query.To.HasValue)
            {
                taskQuery = taskQuery.Where(t => t.Created <= query.To.Value);
            }

            var tasks = await taskQuery
                .OrderByDescending(t => t.Created)
                .Select(t => new
                {
                    t.Id,
                    t.Title,
                    t.BoardId,
                    t.WorkCategory,
                    t.WorkCategoryConfidence,
                    t.AssigneeId,
                    t.Created
                })
                .ToListAsync();

            var boardLookup = await _context.Boards
                .AsNoTracking()
                .Where(b => boardIds.Contains(b.Id))
                .Select(b => new { b.Id, b.Name })
                .ToDictionaryAsync(b => b.Id, b => b.Name);

            var assigneeIds = tasks
                .Where(t => !string.IsNullOrWhiteSpace(t.AssigneeId))
                .Select(t => t.AssigneeId)
                .Distinct()
                .ToList();

            var userLookup = assigneeIds.Any()
                ? await _userManager.Users
                    .Where(u => assigneeIds.Contains(u.Id))
                    .Select(u => new { u.Id, u.UserName })
                    .ToDictionaryAsync(u => u.Id, u => u.UserName)
                : new Dictionary<string, string>();

            return tasks
                .Select(t => new TaskCategoryAuditResponse
                {
                    TaskId = t.Id,
                    TaskTitle = t.Title,
                    BoardId = t.BoardId,
                    BoardName = boardLookup.ContainsKey(t.BoardId) ? boardLookup[t.BoardId] : string.Empty,
                    Category = TaskCategoryHelper.Normalize(t.WorkCategory),
                    CategoryConfidence = Math.Round(t.WorkCategoryConfidence, 3),
                    AssigneeId = t.AssigneeId,
                    AssigneeUsername = !string.IsNullOrWhiteSpace(t.AssigneeId) && userLookup.ContainsKey(t.AssigneeId)
                        ? userLookup[t.AssigneeId]
                        : null,
                    CreatedAt = t.Created
                })
                .ToList();
        }

        [HttpPost("recommend-assignee")]
        public async Task<ActionResult<AssigneeRecommendationResponse>> RecommendAssignee([FromBody] AssigneeRecommendationRequest request)
        {
            var requesterId = GetCurrentUserId();
            if (string.IsNullOrWhiteSpace(requesterId))
            {
                return Unauthorized();
            }

            var board = await _context.Boards
                .AsNoTracking()
                .Include(b => b.Workspace)
                .Include(b => b.Users)
                .FirstOrDefaultAsync(b => b.Id == request.BoardId &&
                    (b.Workspace.UserId == requesterId || b.Users.Any(u => u.UserId == requesterId)));

            if (board == null)
            {
                return NotFound("Board not found or access denied.");
            }

            var candidateUserIds = board.Users.Select(u => u.UserId).Distinct().ToList();
            if (!candidateUserIds.Contains(board.Workspace.UserId))
            {
                candidateUserIds.Add(board.Workspace.UserId);
            }

            if (!candidateUserIds.Any())
            {
                return new AssigneeRecommendationResponse
                {
                    BoardId = request.BoardId,
                    TaskCategory = TaskCategoryHelper.Other,
                    TaskCategoryConfidence = 0,
                    GeneratedAt = DateTime.UtcNow
                };
            }

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

            var workspaceBoardIds = await _context.Boards
                .AsNoTracking()
                .Where(b => b.WorkspaceId == board.WorkspaceId)
                .Select(b => b.Id)
                .ToListAsync();

            var workspaceCurrentTasks = await _context.BoardTasks
                .AsNoTracking()
                .Where(t => workspaceBoardIds.Contains(t.BoardId) && t.AssigneeId != null && candidateUserIds.Contains(t.AssigneeId))
                .Select(t => new CurrentTaskRow
                {
                    TaskId = t.Id,
                    AssigneeId = t.AssigneeId,
                    DueDate = t.DueDate,
                    StatusType = t.Status.Type,
                    StatusTitle = t.Status.Title
                })
                .ToListAsync();

            var workspaceEvents = await _context.TaskEvents
                .AsNoTracking()
                .Where(e => e.WorkspaceId == board.WorkspaceId && candidateUserIds.Contains(e.AssigneeId))
                .Select(e => new TaskEventRow
                {
                    TaskId = e.TaskId,
                    EventType = e.EventType,
                    AssigneeId = e.AssigneeId,
                    Priority = e.Priority,
                    DueDate = e.DueDate,
                    Title = e.Title,
                    Description = e.Description,
                    Created = e.Created
                })
                .ToListAsync();

            var createdEvents = workspaceEvents.Where(e => e.EventType == TaskEventTypes.Created).ToList();
            var completedEvents = workspaceEvents.Where(e => e.EventType == TaskEventTypes.Completed).ToList();
            var createdByTaskId = createdEvents
                .GroupBy(e => e.TaskId)
                .ToDictionary(g => g.Key, g => g.Min(x => x.Created));

            var allCompletedDurations = completedEvents
                .Where(e => createdByTaskId.ContainsKey(e.TaskId) && e.Created >= createdByTaskId[e.TaskId])
                .Select(e => (e.Created - createdByTaskId[e.TaskId]).TotalHours)
                .ToList();

            var globalAverageHours = allCompletedDurations.Any() ? allCompletedDurations.Average() : 24;
            var requestKeywords = ExtractKeywords($"{request.Title} {request.Description}");
            var now = DateTime.UtcNow;

            var userLookup = await _userManager.Users
                .Where(u => candidateUserIds.Contains(u.Id))
                .Select(u => new { u.Id, u.UserName })
                .ToDictionaryAsync(u => u.Id, u => u.UserName);

            var userCategoryScores = await _context.UserCategoryScores
                .AsNoTracking()
                .Where(x => candidateUserIds.Contains(x.UserId) && x.Category == taskCategory)
                .ToDictionaryAsync(x => x.UserId, x => x);

            var candidates = new List<AssigneeRecommendationCandidate>();
            foreach (var candidateId in candidateUserIds)
            {
                var activeTasks = workspaceCurrentTasks
                    .Where(t => t.AssigneeId == candidateId && !IsCompletedStatus(t.StatusType, t.StatusTitle))
                    .ToList();
                var overdueActiveCount = activeTasks.Count(t => t.DueDate.HasValue && t.DueDate.Value < now);

                var completedByUser = completedEvents.Where(e => e.AssigneeId == candidateId).ToList();
                var userDurations = completedByUser
                    .Where(e => createdByTaskId.ContainsKey(e.TaskId) && e.Created >= createdByTaskId[e.TaskId])
                    .Select(e => (e.Created - createdByTaskId[e.TaskId]).TotalHours)
                    .ToList();

                var averageHours = userDurations.Any() ? userDurations.Average() : globalAverageHours;
                var speedScore = globalAverageHours <= 0 ? 0.5 : Clamp01(globalAverageHours / Math.Max(averageHours, 1));

                var dueDateCompletions = completedByUser.Where(e => e.DueDate.HasValue).ToList();
                var onTimeRate = dueDateCompletions.Any()
                    ? (double)dueDateCompletions.Count(e => e.Created <= e.DueDate.Value) / dueDateCompletions.Count
                    : 0.5;

                var priorityMatchRate = completedByUser.Any()
                    ? (double)completedByUser.Count(e => string.Equals(e.Priority, request.Priority, StringComparison.OrdinalIgnoreCase)) / completedByUser.Count
                    : 0.5;

                var expertiseScore = CalculateExpertiseScore(completedByUser, requestKeywords);
                userCategoryScores.TryGetValue(candidateId, out var categoryStat);
                var categoryScore = categoryStat?.Score ?? 50;
                var categoryScoreNormalized = Clamp01(categoryScore / 100.0);
                var categoryCompletedTasks = categoryStat?.CompletedTasks ?? 0;
                var categoryAverageHours = categoryStat?.AverageCompletionHours ?? globalAverageHours;
                var categoryExperience = Math.Min(categoryCompletedTasks, 10) / 10.0;
                var workloadPenalty = Math.Min(activeTasks.Count, 8) / 8.0;
                var overduePenalty = Math.Min(overdueActiveCount, 5) / 5.0;

                var score = 30
                    + (expertiseScore * 18)
                    + (priorityMatchRate * 8)
                    + (onTimeRate * 9)
                    + (speedScore * 15)
                    + (categoryScoreNormalized * 20)
                    + (categoryExperience * 8)
                    - (workloadPenalty * 12)
                    - (overduePenalty * 10);

                if (request.DueDate.HasValue && request.DueDate.Value <= now.AddDays(3) && activeTasks.Count > 3)
                {
                    score -= 8;
                }

                score = Math.Round(Math.Max(0, Math.Min(100, score)), 2);

                candidates.Add(new AssigneeRecommendationCandidate
                {
                    UserId = candidateId,
                    Username = userLookup.ContainsKey(candidateId) ? userLookup[candidateId] : candidateId,
                    Score = score,
                    Signals = new RecommendationSignals
                    {
                        ActiveTasks = activeTasks.Count,
                        OverdueActiveTasks = overdueActiveCount,
                        CompletedTasks = completedByUser.Select(e => e.TaskId).Distinct().Count(),
                        OnTimeRate = Math.Round(onTimeRate * 100, 2),
                        AverageCompletionHours = Math.Round(averageHours, 2),
                        ExpertiseScore = Math.Round(expertiseScore, 3),
                        PriorityMatchRate = Math.Round(priorityMatchRate * 100, 2),
                        Category = taskCategory,
                        CategoryCompletedTasks = categoryCompletedTasks,
                        CategoryAverageCompletionHours = Math.Round(categoryAverageHours, 2),
                        CategoryScore = Math.Round(categoryScore, 2)
                    },
                    Reasons = BuildReasons(
                        expertiseScore,
                        speedScore,
                        onTimeRate,
                        priorityMatchRate,
                        categoryScoreNormalized,
                        categoryCompletedTasks,
                        activeTasks.Count,
                        overdueActiveCount,
                        completedByUser.Count)
                });
            }

            var topN = Math.Max(1, Math.Min(request.TopN, 10));
            return new AssigneeRecommendationResponse
            {
                BoardId = request.BoardId,
                TaskCategory = taskCategory,
                TaskCategoryConfidence = Math.Round(taskCategoryConfidence, 3),
                GeneratedAt = DateTime.UtcNow,
                Candidates = candidates
                    .OrderByDescending(c => c.Score)
                    .ThenBy(c => c.Signals.ActiveTasks)
                    .Take(topN)
                    .ToList()
            };
        }

        private string GetCurrentUserId()
        {
            return User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("uid")?.Value;
        }

        private async Task<List<int>> GetAccessibleBoardIds(string userId, int? workspaceId, int? boardId)
        {
            var query = _context.Boards
                .AsNoTracking()
                .Where(b => b.Workspace.UserId == userId || b.Users.Any(u => u.UserId == userId));

            if (workspaceId.HasValue)
            {
                query = query.Where(b => b.WorkspaceId == workspaceId.Value);
            }

            if (boardId.HasValue)
            {
                query = query.Where(b => b.Id == boardId.Value);
            }

            return await query
                .Select(b => b.Id)
                .Distinct()
                .ToListAsync();
        }

        private async Task<List<CurrentTaskRow>> GetCurrentTaskRows(List<int> boardIds)
        {
            return await _context.BoardTasks
                .AsNoTracking()
                .Where(t => boardIds.Contains(t.BoardId))
                .Select(t => new CurrentTaskRow
                {
                    TaskId = t.Id,
                    AssigneeId = t.AssigneeId,
                    DueDate = t.DueDate,
                    Created = t.Created,
                    StatusType = t.Status.Type,
                    StatusTitle = t.Status.Title
                })
                .ToListAsync();
        }

        private async Task<List<TaskEventRow>> GetTaskEvents(List<int> boardIds)
        {
            return await _context.TaskEvents
                .AsNoTracking()
                .Where(e => boardIds.Contains(e.BoardId))
                .Select(e => new TaskEventRow
                {
                    TaskId = e.TaskId,
                    EventType = e.EventType,
                    AssigneeId = e.AssigneeId,
                    Priority = e.Priority,
                    DueDate = e.DueDate,
                    Title = e.Title,
                    Description = e.Description,
                    Created = e.Created
                })
                .ToListAsync();
        }

        private static List<double> CalculateCompletionDurations(List<TaskEventRow> createdEvents, List<TaskEventRow> completedEvents)
        {
            var createdByTaskId = createdEvents
                .GroupBy(e => e.TaskId)
                .ToDictionary(g => g.Key, g => g.Min(x => x.Created));

            return completedEvents
                .Where(e => createdByTaskId.ContainsKey(e.TaskId) && e.Created >= createdByTaskId[e.TaskId])
                .Select(e => (e.Created - createdByTaskId[e.TaskId]).TotalHours)
                .ToList();
        }

        private static double CalculateTaskSpeedScore(double completionHours, string priority)
        {
            var priorityFactor = string.Equals(priority, "high", StringComparison.OrdinalIgnoreCase)
                ? 1.35
                : string.Equals(priority, "low", StringComparison.OrdinalIgnoreCase)
                    ? 0.9
                    : 1.0;
            var normalizedHours = completionHours / priorityFactor;
            return Math.Clamp(100 - (normalizedHours * 5), 5, 100);
        }

        private static bool IsCompletedStatus(string statusType, string statusTitle)
        {
            if (!string.IsNullOrWhiteSpace(statusType) &&
                string.Equals(statusType.Trim(), BoardStatus.Done, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            if (string.IsNullOrWhiteSpace(statusTitle))
            {
                return false;
            }

            var normalizedTitle = statusTitle.Trim().ToLowerInvariant();
            return CompletedStatusKeywords.Contains(normalizedTitle) ||
                CompletedStatusKeywords.Any(keyword => normalizedTitle.Contains(keyword));
        }

        private static bool IsInRange(DateTime value, DateTime? from, DateTime? to)
        {
            if (from.HasValue && value < from.Value)
            {
                return false;
            }

            if (to.HasValue && value > to.Value)
            {
                return false;
            }

            return true;
        }

        private static HashSet<string> ExtractKeywords(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return new HashSet<string>();
            }

            var tokens = Regex.Split(text.ToLowerInvariant(), @"[^a-z0-9]+")
                .Where(token => token.Length >= 3 && !StopWords.Contains(token))
                .Distinct();

            return new HashSet<string>(tokens);
        }

        private static double CalculateExpertiseScore(List<TaskEventRow> completedEvents, HashSet<string> requestKeywords)
        {
            if (!completedEvents.Any() || requestKeywords == null || requestKeywords.Count == 0)
            {
                return 0;
            }

            var maxScore = 0.0;
            foreach (var evt in completedEvents)
            {
                var eventKeywords = ExtractKeywords($"{evt.Title} {evt.Description}");
                if (!eventKeywords.Any())
                {
                    continue;
                }

                var intersection = requestKeywords.Intersect(eventKeywords).Count();
                var union = requestKeywords.Union(eventKeywords).Count();
                var jaccard = union == 0 ? 0 : (double)intersection / union;
                maxScore = Math.Max(maxScore, jaccard);
            }

            return maxScore;
        }

        private static double Clamp01(double value)
        {
            return Math.Max(0, Math.Min(1, value));
        }

        private static List<string> BuildReasons(
            double expertiseScore,
            double speedScore,
            double onTimeRate,
            double priorityMatchRate,
            double categoryScore,
            int categoryCompletedTasks,
            int activeCount,
            int overdueActiveCount,
            int completedCount)
        {
            var reasons = new List<string>();

            if (expertiseScore >= 0.3)
            {
                reasons.Add("Strong historical performance on similar tasks.");
            }

            if (speedScore >= 0.7)
            {
                reasons.Add("Tends to complete tasks faster than team average.");
            }

            if (onTimeRate >= 0.7)
            {
                reasons.Add("High deadline adherence.");
            }

            if (priorityMatchRate >= 0.6)
            {
                reasons.Add("Strong experience with tasks at the same priority level.");
            }

            if (categoryScore >= 0.65 && categoryCompletedTasks >= 2)
            {
                reasons.Add("Strong track record in this task category.");
            }
            else if (categoryCompletedTasks == 0)
            {
                reasons.Add("Limited historical data in this task category.");
            }

            if (activeCount <= 2)
            {
                reasons.Add("Current workload is suitable for assignment.");
            }

            if (overdueActiveCount > 0)
            {
                reasons.Add("Risk penalty applied due to overdue active tasks.");
            }

            if (completedCount == 0)
            {
                reasons.Add("Limited history of completed tasks.");
            }

            return reasons.Take(3).ToList();
        }

        private class CurrentTaskRow
        {
            public int TaskId { get; set; }
            public string AssigneeId { get; set; }
            public DateTime? DueDate { get; set; }
            public DateTime Created { get; set; }
            public string StatusType { get; set; }
            public string StatusTitle { get; set; }
        }

        private class CategoryPerformanceTaskRow
        {
            public int TaskId { get; set; }
            public string AssigneeId { get; set; }
            public string WorkCategory { get; set; }
            public string Priority { get; set; }
            public DateTime? DueDate { get; set; }
            public DateTime? AssignedAt { get; set; }
            public DateTime Created { get; set; }
            public string StatusType { get; set; }
            public string StatusTitle { get; set; }
        }

        private class TaskEventRow
        {
            public int TaskId { get; set; }
            public string EventType { get; set; }
            public string AssigneeId { get; set; }
            public string Priority { get; set; }
            public DateTime? DueDate { get; set; }
            public string Title { get; set; }
            public string Description { get; set; }
            public DateTime Created { get; set; }
        }
    }
}
