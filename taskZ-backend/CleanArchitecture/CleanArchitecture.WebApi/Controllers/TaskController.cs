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

namespace CleanArchitecture.WebApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class TaskController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
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
            public const string Updated = "Updated";
            public const string StatusChanged = "StatusChanged";
            public const string AssigneeChanged = "AssigneeChanged";
            public const string Completed = "Completed";
            public const string Reopened = "Reopened";
            public const string Deleted = "Deleted";
        }

        public TaskController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
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
                Priority = task.Priority,
                DueDate = task.DueDate,
                Title = task.Title,
                Description = task.Description,
                Metadata = metadata
            };
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
                Position = maxPosition + 1
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
            var statusChanged = false;
            var assigneeChanged = false;

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

            await _context.SaveChangesAsync();

            var changedEvents = new List<TaskEvent>();
            var isAnyFieldUpdated = oldTitle != task.Title
                || oldDescription != task.Description
                || oldPriority != task.Priority
                || oldDueDate != task.DueDate;

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
                var wasCompleted = IsCompletedStatus(oldStatus?.Type, oldStatus?.Title);
                var isCompleted = IsCompletedStatus(newStatus?.Type, newStatus?.Title);

                if (!wasCompleted && isCompleted)
                {
                    changedEvents.Add(BuildTaskEvent(task, task.Board.WorkspaceId, TaskEventTypes.Completed, userId));
                }
                else if (wasCompleted && !isCompleted)
                {
                    changedEvents.Add(BuildTaskEvent(task, task.Board.WorkspaceId, TaskEventTypes.Reopened, userId));
                }
            }

            if (changedEvents.Any())
            {
                _context.TaskEvents.AddRange(changedEvents);
                await _context.SaveChangesAsync();
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

            return NoContent();
        }
    }
} 
