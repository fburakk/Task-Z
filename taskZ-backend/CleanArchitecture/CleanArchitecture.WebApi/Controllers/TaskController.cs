using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using CleanArchitecture.Core.DTOs.BoardTask;
using CleanArchitecture.Core.Entities;
using CleanArchitecture.Infrastructure.Contexts;
using CleanArchitecture.Infrastructure.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using CleanArchitecture.WebApi.Services;

namespace CleanArchitecture.WebApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class TaskController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ITaskClassificationService _taskClassificationService;
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
            public const string Updated = "Updated";
            public const string StatusChanged = "StatusChanged";
            public const string AssigneeChanged = "AssigneeChanged";
            public const string Completed = "Completed";
            public const string Reopened = "Reopened";
            public const string Deleted = "Deleted";
        }

        public TaskController(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager,
            ITaskClassificationService taskClassificationService)
        {
            _context = context;
            _userManager = userManager;
            _taskClassificationService = taskClassificationService;
        }

        private string GetCurrentUserId()
        {
            return User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("uid")?.Value;
        }

        private static bool IsCompletedStatus(string statusType, string statusTitle = null)
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

        private TaskEvent BuildTaskEvent(
            BoardTask task,
            int workspaceId,
            string eventType,
            string actorUserId,
            int? fromStatusId = null,
            int? toStatusId = null,
            string fromAssigneeId = null,
            string toAssigneeId = null,
            string metadata = null)
        {
            return new TaskEvent
            {
                TaskId = task.Id,
                BoardId = task.BoardId,
                WorkspaceId = workspaceId,
                EventType = eventType,
                ActorUserId = actorUserId,
                StatusId = task.StatusId,
                FromStatusId = fromStatusId,
                ToStatusId = toStatusId,
                AssigneeId = task.AssigneeId,
                FromAssigneeId = fromAssigneeId,
                ToAssigneeId = toAssigneeId,
                AssignedAt = eventType == TaskEventTypes.Completed ? task.AssignedAt : null,
                Priority = task.Priority,
                DueDate = task.DueDate,
                Title = task.Title,
                Description = task.Description,
                Metadata = metadata
            };
        }

        private static string ResolveWorkCategory(string requestedCategory, string aiCategory)
        {
            if (!string.IsNullOrWhiteSpace(requestedCategory))
            {
                return TaskCategoryHelper.Normalize(requestedCategory);
            }

            return TaskCategoryHelper.Normalize(aiCategory);
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

        private async Task RecalculateUserCategoryScoresAsync(IEnumerable<string> userIds)
        {
            var impactedUserIds = userIds
                .Where(id => !string.IsNullOrWhiteSpace(id))
                .Distinct()
                .ToList();

            if (!impactedUserIds.Any())
            {
                return;
            }

            var completedTasks = await _context.BoardTasks
                .AsNoTracking()
                .Where(t => t.AssigneeId != null && impactedUserIds.Contains(t.AssigneeId))
                .Select(t => new
                {
                    t.Id,
                    t.AssigneeId,
                    t.WorkCategory,
                    t.Priority,
                    t.DueDate,
                    t.AssignedAt,
                    t.Created,
                    StatusType = t.Status.Type,
                    StatusTitle = t.Status.Title
                })
                .ToListAsync();

            var currentlyCompletedTasks = completedTasks
                .Where(t => IsCompletedStatus(t.StatusType, t.StatusTitle))
                .ToList();

            var completedTaskIds = currentlyCompletedTasks.Select(t => t.Id).ToList();
            var completedAtLookup = completedTaskIds.Any()
                ? await _context.TaskEvents
                    .AsNoTracking()
                    .Where(e => e.EventType == TaskEventTypes.Completed && completedTaskIds.Contains(e.TaskId))
                    .GroupBy(e => e.TaskId)
                    .Select(g => new { TaskId = g.Key, CompletedAt = g.Max(x => x.Created) })
                    .ToDictionaryAsync(x => x.TaskId, x => x.CompletedAt)
                : new Dictionary<int, DateTime>();

            var recalculatedStats = currentlyCompletedTasks
                .GroupBy(t => new
                {
                    UserId = t.AssigneeId,
                    Category = TaskCategoryHelper.Normalize(t.WorkCategory)
                })
                .Select(group =>
                {
                    var taskStats = group.Select(task =>
                    {
                        var completedAt = completedAtLookup.ContainsKey(task.Id) ? completedAtLookup[task.Id] : task.Created;
                        var effectiveStart = task.AssignedAt ?? task.Created;
                        var completionHours = Math.Max(0.1, (completedAt - effectiveStart).TotalHours);
                        var speedScore = CalculateTaskSpeedScore(completionHours, task.Priority);
                        var onTime = !task.DueDate.HasValue || completedAt <= task.DueDate.Value;

                        return new
                        {
                            task.Id,
                            CompletedAt = completedAt,
                            CompletionHours = completionHours,
                            SpeedScore = speedScore,
                            OnTime = onTime
                        };
                    }).ToList();

                    var latestTask = taskStats
                        .OrderByDescending(x => x.CompletedAt)
                        .First();

                    return new UserCategoryScore
                    {
                        UserId = group.Key.UserId,
                        Category = group.Key.Category,
                        CompletedTasks = taskStats.Count,
                        OnTimeCompletedTasks = taskStats.Count(x => x.OnTime),
                        TotalCompletionHours = taskStats.Sum(x => x.CompletionHours),
                        AverageCompletionHours = taskStats.Average(x => x.CompletionHours),
                        Score = Math.Round(taskStats.Average(x => x.SpeedScore), 2),
                        LastCompletedAt = latestTask.CompletedAt,
                        LastTaskId = latestTask.Id
                    };
                })
                .ToList();

            var existingStats = await _context.UserCategoryScores
                .Where(x => impactedUserIds.Contains(x.UserId))
                .ToListAsync();

            foreach (var recalculated in recalculatedStats)
            {
                var existing = existingStats.FirstOrDefault(x =>
                    x.UserId == recalculated.UserId &&
                    x.Category == recalculated.Category);

                if (existing == null)
                {
                    _context.UserCategoryScores.Add(recalculated);
                    continue;
                }

                existing.CompletedTasks = recalculated.CompletedTasks;
                existing.OnTimeCompletedTasks = recalculated.OnTimeCompletedTasks;
                existing.TotalCompletionHours = recalculated.TotalCompletionHours;
                existing.AverageCompletionHours = recalculated.AverageCompletionHours;
                existing.Score = recalculated.Score;
                existing.LastCompletedAt = recalculated.LastCompletedAt;
                existing.LastTaskId = recalculated.LastTaskId;
            }

            var activeKeys = recalculatedStats
                .Select(x => $"{x.UserId}::{x.Category}")
                .ToHashSet(StringComparer.Ordinal);
            var staleStats = existingStats
                .Where(x => !activeKeys.Contains($"{x.UserId}::{x.Category}"))
                .ToList();
            if (staleStats.Any())
            {
                _context.UserCategoryScores.RemoveRange(staleStats);
            }

            await _context.SaveChangesAsync();
        }

        private async Task<TaskDto> MapToTaskDto(BoardTask task, string assigneeUsername = null)
        {
            var createdByUser = await _userManager.FindByIdAsync(task.CreatedBy);
            var lastModifiedByUser = task.LastModifiedBy != null ? await _userManager.FindByIdAsync(task.LastModifiedBy) : null;
            var assigneeUser = task.AssigneeId != null ? await _userManager.FindByIdAsync(task.AssigneeId) : null;

            return new TaskDto
            {
                Id = task.Id,
                BoardId = task.BoardId,
                StatusId = task.StatusId,
                Title = task.Title,
                Description = task.Description,
                Priority = task.Priority,
                DueDate = task.DueDate,
                AssigneeId = task.AssigneeId,
                AssigneeUsername = assigneeUsername ?? assigneeUser?.UserName,
                WorkCategory = TaskCategoryHelper.Normalize(task.WorkCategory),
                WorkCategoryConfidence = task.WorkCategoryConfidence,
                Position = task.Position,
                CreatedBy = task.CreatedBy,
                CreatedByUsername = createdByUser?.UserName,
                Created = task.Created,
                LastModifiedBy = task.LastModifiedBy,
                LastModifiedByUsername = lastModifiedByUser?.UserName,
                LastModified = task.LastModified
            };
        }

        [HttpGet("assigned")]
        public async Task<ActionResult<List<TaskDto>>> GetAssignedTasks()
        {
            var userId = GetCurrentUserId();
            
            var tasks = await _context.BoardTasks
                .Include(t => t.Board)
                .ThenInclude(b => b.Workspace)
                .Where(t => t.AssigneeId == userId &&
                    (t.Board.Workspace.UserId == userId || // User owns the workspace
                     t.Board.Users.Any(u => u.UserId == userId))) // User is a board member
                .OrderBy(t => t.DueDate)
                .ThenBy(t => t.Priority)
                .ToListAsync();

            var taskDtos = new List<TaskDto>();
            foreach (var task in tasks)
            {
                taskDtos.Add(await MapToTaskDto(task));
            }

            return taskDtos;
        }

        [HttpGet("board/{boardId}")]
        public async Task<ActionResult<List<TaskDto>>> GetBoardTasks(int boardId)
        {
            var userId = GetCurrentUserId();
            
            // Verify board access
            var hasAccess = await _context.Boards
                .Include(b => b.Workspace)
                .Include(b => b.Users)
                .AnyAsync(b => b.Id == boardId && 
                    (b.Workspace.UserId == userId || // Workspace owner
                     b.Users.Any(u => u.UserId == userId))); // Board member
                
            if (!hasAccess)
            {
                return NotFound("Board not found or access denied.");
            }

            var tasks = await _context.BoardTasks
                .AsNoTracking()  // Explicitly get fresh data
                .Where(t => t.BoardId == boardId)
                .OrderBy(t => t.StatusId)
                .ThenBy(t => t.Position)
                .ToListAsync();

            var taskDtos = new List<TaskDto>();
            foreach (var task in tasks)
            {
                taskDtos.Add(await MapToTaskDto(task));
            }

            return taskDtos;
        }

        [HttpGet("status/{statusId}")]
        public async Task<ActionResult<List<TaskDto>>> GetStatusTasks(int statusId)
        {
            var userId = GetCurrentUserId();
            
            // Verify status access
            var hasAccess = await _context.BoardStatuses
                .Include(bs => bs.Board)
                .ThenInclude(b => b.Workspace)
                .Include(bs => bs.Board)
                .ThenInclude(b => b.Users)
                .AnyAsync(bs => bs.Id == statusId && 
                    (bs.Board.Workspace.UserId == userId || // Workspace owner
                     bs.Board.Users.Any(u => u.UserId == userId))); // Board member
                
            if (!hasAccess)
            {
                return NotFound("Status not found or access denied.");
            }

            var tasks = await _context.BoardTasks
                .Where(t => t.StatusId == statusId)
                .OrderBy(t => t.Position)
                .ToListAsync();

            var taskDtos = new List<TaskDto>();
            foreach (var task in tasks)
            {
                taskDtos.Add(await MapToTaskDto(task));
            }

            return taskDtos;
        }

        [HttpPost("board/{boardId}")]
        public async Task<ActionResult<TaskDto>> CreateTask(int boardId, CreateTaskRequest request)
        {
            var userId = GetCurrentUserId();
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }
            
            // Verify board access and get statuses
            var board = await _context.Boards
                .Include(b => b.Workspace)
                .Include(b => b.Statuses)
                .Include(b => b.Users)
                .FirstOrDefaultAsync(b => b.Id == boardId && 
                    (b.Workspace.UserId == userId || // Workspace owner
                     b.Users.Any(u => u.UserId == userId))); // Board member
                
            if (board == null)
            {
                return NotFound("Board not found or access denied.");
            }

            // Find user by username if provided
            string assigneeId = null;
            if (!string.IsNullOrEmpty(request.Username))
            {
                var assignee = await _userManager.FindByNameAsync(request.Username);
                if (assignee == null)
                {
                    return NotFound($"User '{request.Username}' not found.");
                }
                assigneeId = assignee.Id;
            }

            int targetStatusId;
            if (request.StatusId.HasValue)
            {
                // Verify the requested status belongs to this board
                var requestedStatus = board.Statuses.FirstOrDefault(s => s.Id == request.StatusId.Value);
                if (requestedStatus == null)
                {
                    return BadRequest("Specified status does not belong to this board.");
                }
                targetStatusId = requestedStatus.Id;
            }
            else
            {
                // Prefer deterministic Todo anchor; fallback to first status.
                var defaultStatus = board.Statuses
                    .OrderByDescending(s => s.Type == BoardStatus.Todo)
                    .ThenBy(s => s.Position)
                    .FirstOrDefault();

                if (defaultStatus == null)
                {
                    return BadRequest("Board must have at least one status.");
                }
                targetStatusId = defaultStatus.Id;
            }

            var createdAtUtc = DateTime.UtcNow;
            string workCategory;
            double workCategoryConfidence;
            if (!string.IsNullOrWhiteSpace(request.WorkCategory))
            {
                workCategory = TaskCategoryHelper.Normalize(request.WorkCategory);
                workCategoryConfidence = 1;
            }
            else
            {
                var classification = await _taskClassificationService.ClassifyAsync(request.Title, request.Description);
                workCategory = ResolveWorkCategory(null, classification.Category);
                workCategoryConfidence = classification.Confidence;
            }

            // Get max position in the target status
            var maxPosition = await _context.BoardTasks
                .Where(t => t.StatusId == targetStatusId)
                .Select(t => t.Position)
                .DefaultIfEmpty()
                .MaxAsync();

            var task = new BoardTask
            {
                BoardId = boardId,
                StatusId = targetStatusId,
                Title = request.Title,
                Description = request.Description,
                Priority = request.Priority,
                DueDate = request.DueDate,
                AssigneeId = assigneeId,
                AssignedAt = assigneeId != null ? DateTime.UtcNow : null,
                Position = maxPosition + 1,
                WorkCategory = workCategory,
                WorkCategoryConfidence = workCategoryConfidence,
                WorkCategoryClassifiedAt = createdAtUtc
            };

            _context.BoardTasks.Add(task);
            await _context.SaveChangesAsync();

            var status = board.Statuses.FirstOrDefault(s => s.Id == task.StatusId);
            _context.TaskEvents.Add(BuildTaskEvent(task, board.WorkspaceId, TaskEventTypes.Created, userId));

            if (IsCompletedStatus(status?.Type, status?.Title))
            {
                _context.TaskEvents.Add(BuildTaskEvent(task, board.WorkspaceId, TaskEventTypes.Completed, userId));
            }

            await _context.SaveChangesAsync();

            if (IsCompletedStatus(status?.Type, status?.Title) && !string.IsNullOrWhiteSpace(task.AssigneeId))
            {
                await RecalculateUserCategoryScoresAsync(new[] { task.AssigneeId });
            }

            return await MapToTaskDto(task, request.Username);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<TaskDto>> UpdateTask(int id, UpdateTaskRequest request)
        {
            var userId = GetCurrentUserId();
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }
            
            var task = await _context.BoardTasks
                .Include(t => t.Board)
                .ThenInclude(b => b.Workspace)
                .Include(t => t.Board)
                .ThenInclude(b => b.Users)
                .AsTracking()  // Enable tracking for this query
                .FirstOrDefaultAsync(t => t.Id == id && 
                    (t.Board.Workspace.UserId == userId || // User owns the workspace
                     t.Board.Users.Any(u => u.UserId == userId))); // User is a board member

            if (task == null)
            {
                return NotFound("Task not found or access denied.");
            }

            var oldStatusId = task.StatusId;
            var oldAssigneeId = task.AssigneeId;
            var oldTitle = task.Title;
            var oldDescription = task.Description;
            var oldPriority = task.Priority;
            var oldDueDate = task.DueDate;
            var oldWorkCategory = task.WorkCategory;
            var statusChanged = false;
            var assigneeChanged = false;
            var wasCompletedBeforeStatusChange = false;
            var isCompletedAfterStatusChange = false;
            var statusCompletionEvaluated = false;

            string assigneeUsername = null;
            // Update assignee if username provided
            if (!string.IsNullOrEmpty(request.Username))
            {
                var assignee = await _userManager.FindByNameAsync(request.Username);
                if (assignee == null)
                {
                    return NotFound($"User '{request.Username}' not found.");
                }
                if (task.AssigneeId != assignee.Id)
                {
                    task.AssigneeId = assignee.Id;
                    task.AssignedAt = DateTime.UtcNow;
                    assigneeChanged = true;
                }
                assigneeUsername = request.Username;
            }

            // If status is changing, update positions
            if (request.StatusId.HasValue && request.StatusId.Value != task.StatusId)
            {
                // Verify status belongs to the same board
                var statusExists = await _context.BoardStatuses
                    .AnyAsync(bs => bs.Id == request.StatusId.Value && bs.BoardId == task.BoardId);
                    
                if (!statusExists)
                {
                    return BadRequest("Invalid status ID.");
                }

                // Get max position in the new status
                var maxPosition = await _context.BoardTasks
                    .Where(t => t.StatusId == request.StatusId.Value)
                    .Select(t => t.Position)
                    .DefaultIfEmpty()
                    .MaxAsync();

                statusChanged = true;
                task.StatusId = request.StatusId.Value;
                task.Position = maxPosition + 1;
            }
            else if (request.Position.HasValue && request.Position.Value != task.Position)
            {
                // Update positions of other tasks in the same status
                var tasksToUpdate = await _context.BoardTasks
                    .Where(t => t.StatusId == task.StatusId && t.Id != task.Id)
                    .OrderBy(t => t.Position)
                    .ToListAsync();

                var newPosition = Math.Max(0, Math.Min(request.Position.Value, tasksToUpdate.Count));
                var oldPosition = task.Position;

                if (newPosition < oldPosition)
                {
                    foreach (var t in tasksToUpdate.Where(t => t.Position >= newPosition && t.Position < oldPosition))
                    {
                        t.Position++;
                    }
                }
                else
                {
                    foreach (var t in tasksToUpdate.Where(t => t.Position > oldPosition && t.Position <= newPosition))
                    {
                        t.Position--;
                    }
                }

                task.Position = newPosition;
            }

            // Only update fields that are provided in the request
            if (request.Title != null)
                task.Title = request.Title;
            if (request.Description != null)
                task.Description = request.Description;
            if (request.Priority != null)
                task.Priority = request.Priority;
            if (request.DueDate.HasValue)
                task.DueDate = request.DueDate;
            if (request.WorkCategory != null)
            {
                task.WorkCategory = TaskCategoryHelper.Normalize(request.WorkCategory);
                task.WorkCategoryConfidence = 1;
                task.WorkCategoryClassifiedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            var changedEvents = new List<TaskEvent>();
            var isAnyFieldUpdated = oldTitle != task.Title
                || oldDescription != task.Description
                || oldPriority != task.Priority
                || oldDueDate != task.DueDate
                || oldWorkCategory != task.WorkCategory;

            if (isAnyFieldUpdated)
            {
                changedEvents.Add(BuildTaskEvent(task, task.Board.WorkspaceId, TaskEventTypes.Updated, userId));
            }

            if (assigneeChanged)
            {
                changedEvents.Add(BuildTaskEvent(
                    task,
                    task.Board.WorkspaceId,
                    TaskEventTypes.AssigneeChanged,
                    userId,
                    fromAssigneeId: oldAssigneeId,
                    toAssigneeId: task.AssigneeId));
            }

            if (statusChanged)
            {
                changedEvents.Add(BuildTaskEvent(
                    task,
                    task.Board.WorkspaceId,
                    TaskEventTypes.StatusChanged,
                    userId,
                    fromStatusId: oldStatusId,
                    toStatusId: task.StatusId));

                var statusTitles = await _context.BoardStatuses
                    .Where(s => s.Id == oldStatusId || s.Id == task.StatusId)
                    .Select(s => new { s.Id, s.Type, s.Title })
                    .ToListAsync();

                var oldStatus = statusTitles.FirstOrDefault(s => s.Id == oldStatusId);
                var newStatus = statusTitles.FirstOrDefault(s => s.Id == task.StatusId);
                wasCompletedBeforeStatusChange = IsCompletedStatus(oldStatus?.Type, oldStatus?.Title);
                isCompletedAfterStatusChange = IsCompletedStatus(newStatus?.Type, newStatus?.Title);
                statusCompletionEvaluated = true;

                if (!wasCompletedBeforeStatusChange && isCompletedAfterStatusChange)
                {
                    changedEvents.Add(BuildTaskEvent(task, task.Board.WorkspaceId, TaskEventTypes.Completed, userId));
                }
                else if (wasCompletedBeforeStatusChange && !isCompletedAfterStatusChange)
                {
                    changedEvents.Add(BuildTaskEvent(task, task.Board.WorkspaceId, TaskEventTypes.Reopened, userId));
                }
            }

            var shouldRecalculateCategoryScores = false;
            var fieldsAffectingScoreChanged = assigneeChanged
                || oldPriority != task.Priority
                || oldDueDate != task.DueDate
                || oldWorkCategory != task.WorkCategory;

            if (statusChanged || fieldsAffectingScoreChanged)
            {
                var currentStatus = statusCompletionEvaluated
                    ? null
                    : await _context.BoardStatuses
                        .Where(s => s.Id == task.StatusId)
                        .Select(s => new { s.Type, s.Title })
                        .FirstOrDefaultAsync();

                var isCompletedNow = statusCompletionEvaluated
                    ? isCompletedAfterStatusChange
                    : IsCompletedStatus(currentStatus?.Type, currentStatus?.Title);

                shouldRecalculateCategoryScores =
                    (statusChanged && statusCompletionEvaluated && wasCompletedBeforeStatusChange != isCompletedAfterStatusChange)
                    || (isCompletedNow && fieldsAffectingScoreChanged);
            }

            if (changedEvents.Any())
            {
                _context.TaskEvents.AddRange(changedEvents);
                await _context.SaveChangesAsync();
            }

            if (shouldRecalculateCategoryScores)
            {
                await RecalculateUserCategoryScoresAsync(new[] { oldAssigneeId, task.AssigneeId });
            }

            return await MapToTaskDto(task, assigneeUsername);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteTask(int id)
        {
            var userId = GetCurrentUserId();
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }
            
            var task = await _context.BoardTasks
                .Include(t => t.Board)
                .ThenInclude(b => b.Workspace)
                .Include(t => t.Board)
                .ThenInclude(b => b.Users)
                .FirstOrDefaultAsync(t => t.Id == id && 
                    (t.Board.Workspace.UserId == userId || // User owns the workspace
                     t.Board.Users.Any(u => u.UserId == userId))); // User is a board member

            if (task == null)
            {
                return NotFound("Task not found or access denied.");
            }

            _context.TaskEvents.Add(BuildTaskEvent(
                task,
                task.Board.WorkspaceId,
                TaskEventTypes.Deleted,
                userId,
                metadata: "Task hard deleted"));
            _context.BoardTasks.Remove(task);
            await _context.SaveChangesAsync();

            if (!string.IsNullOrWhiteSpace(task.AssigneeId))
            {
                await RecalculateUserCategoryScoresAsync(new[] { task.AssigneeId });
            }

            return NoContent();
        }
    }
} 
