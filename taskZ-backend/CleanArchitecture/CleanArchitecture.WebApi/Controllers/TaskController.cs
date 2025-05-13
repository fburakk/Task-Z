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

        public TaskController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
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
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
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
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
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
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
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
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
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
                // Default to first status
                var firstStatus = board.Statuses.OrderBy(s => s.Position).FirstOrDefault();
                if (firstStatus == null)
                {
                    return BadRequest("Board must have at least one status.");
                }
                targetStatusId = firstStatus.Id;
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

            return await MapToTaskDto(task, request.Username);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<TaskDto>> UpdateTask(int id, UpdateTaskRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
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

            string assigneeUsername = null;
            // Update assignee if username provided
            if (!string.IsNullOrEmpty(request.Username))
            {
                var assignee = await _userManager.FindByNameAsync(request.Username);
                if (assignee == null)
                {
                    return NotFound($"User '{request.Username}' not found.");
                }
                task.AssigneeId = assignee.Id;
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

            return await MapToTaskDto(task, assigneeUsername);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteTask(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
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

            _context.BoardTasks.Remove(task);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
} 