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
            "and", "the", "for", "with", "that", "this", "from", "task", "todo", "bir", "ile", "icin", "için", "gorev", "görev"
        };
        private static readonly HashSet<string> CompletedStatusKeywords = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "done",
            "completed",
            "complete",
            "closed",
            "finish",
            "finished",
            "tamam",
            "tamamlandi",
            "tamamlandı",
            "bitti",
            "bitirildi"
        };

        private static class TaskEventTypes
        {
            public const string Created = "Created";
            public const string Completed = "Completed";
        }

        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public AnalyticsController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
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

            var totalTaskIds = currentTasks.Select(t => t.TaskId).Union(createdEvents.Select(e => e.TaskId)).Distinct().ToList();
            var completedCurrentTasks = currentTasks.Count(t => IsCompletedStatus(t.StatusType, t.StatusTitle));

            var completionDurations = CalculateCompletionDurations(createdEvents, completedEvents);
            var overview = new AnalyticsOverviewResponse
            {
                TotalTasks = totalTaskIds.Count,
                CompletedTasks = completedCurrentTasks,
                ActiveTasks = currentTasks.Count - completedCurrentTasks,
                OverdueTasks = currentTasks.Count(t => !IsCompletedStatus(t.StatusType, t.StatusTitle) && t.DueDate.HasValue && t.DueDate.Value < DateTime.UtcNow),
                CreatedInRange = createdEvents.Count(e => IsInRange(e.Created, query.From, query.To)),
                CompletedInRange = completedEvents.Count(e => IsInRange(e.Created, query.From, query.To)),
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
                var completedByUser = completedEvents.Where(e => e.AssigneeId == userId).ToList();
                var completedTaskCount = completedByUser.Select(e => e.TaskId).Distinct().Count();
                var completedInRange = completedByUser.Where(e => IsInRange(e.Created, query.From, query.To)).Select(e => e.TaskId).Distinct().Count();

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
                    GeneratedAt = DateTime.UtcNow
                };
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
                var workloadPenalty = Math.Min(activeTasks.Count, 8) / 8.0;
                var overduePenalty = Math.Min(overdueActiveCount, 5) / 5.0;

                var score = 45
                    + (expertiseScore * 20)
                    + (priorityMatchRate * 10)
                    + (onTimeRate * 10)
                    + (speedScore * 20)
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
                        PriorityMatchRate = Math.Round(priorityMatchRate * 100, 2)
                    },
                    Reasons = BuildReasons(expertiseScore, speedScore, onTimeRate, priorityMatchRate, activeTasks.Count, overdueActiveCount, completedByUser.Count)
                });
            }

            var topN = Math.Max(1, Math.Min(request.TopN, 10));
            return new AssigneeRecommendationResponse
            {
                BoardId = request.BoardId,
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

            var tokens = Regex.Split(text.ToLowerInvariant(), @"[^a-z0-9ğüşöçıİ]+")
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
            int activeCount,
            int overdueActiveCount,
            int completedCount)
        {
            var reasons = new List<string>();

            if (expertiseScore >= 0.3)
            {
                reasons.Add("Benzer görevlerde geçmiş performansı güçlü.");
            }

            if (speedScore >= 0.7)
            {
                reasons.Add("Takım ortalamasına göre daha hızlı tamamlama eğilimi var.");
            }

            if (onTimeRate >= 0.7)
            {
                reasons.Add("Deadline uyumu yüksek.");
            }

            if (priorityMatchRate >= 0.6)
            {
                reasons.Add("Aynı öncelik seviyesindeki görevlerde deneyimi yüksek.");
            }

            if (activeCount <= 2)
            {
                reasons.Add("Mevcut iş yükü atama için uygun.");
            }

            if (overdueActiveCount > 0)
            {
                reasons.Add("Aktif geciken görevleri bulunduğu için risk puanı yansıtıldı.");
            }

            if (completedCount == 0)
            {
                reasons.Add("Geçmiş tamamlanmış görev verisi sınırlı.");
            }

            return reasons.Take(3).ToList();
        }

        private class CurrentTaskRow
        {
            public int TaskId { get; set; }
            public string AssigneeId { get; set; }
            public DateTime? DueDate { get; set; }
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
