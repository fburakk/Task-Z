using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using CleanArchitecture.Core.DTOs.BoardTask;
using CleanArchitecture.Core.Entities;
using CleanArchitecture.Infrastructure.Contexts;
using Microsoft.AspNetCore.Authorization;
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

        public TaskController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpGet("board/{boardId}")]
        public async Task<ActionResult<List<TaskDto>>> GetBoardTasks(int boardId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            // Verify board access
            var hasAccess = await _context.Boards
                .Include(b => b.Workspace)
                .AnyAsync(b => b.Id == boardId && b.Workspace.UserId == userId);
                
            if (!hasAccess)
            {
                return NotFound("Board not found or access denied.");
            }

            var tasks = await _context.BoardTasks
                .Where(t => t.BoardId == boardId)
                .OrderBy(t => t.StatusId)
                .ThenBy(t => t.Position)
                .Select(t => new TaskDto
                {
                    Id = t.Id,
                    BoardId = t.BoardId,
                    StatusId = t.StatusId,
                    Title = t.Title,
                    Description = t.Description,
                    Priority = t.Priority,
                    DueDate = t.DueDate,
                    AssigneeId = t.AssigneeId,
                    Position = t.Position,
                    CreatedBy = t.CreatedBy,
                    Created = t.Created,
                    LastModifiedBy = t.LastModifiedBy,
                    LastModified = t.LastModified
                })
                .ToListAsync();

            return tasks;
        }

        [HttpGet("status/{statusId}")]
        public async Task<ActionResult<List<TaskDto>>> GetStatusTasks(int statusId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            // Verify status access
            var hasAccess = await _context.BoardStatuses
                .Include(bs => bs.Board)
                .ThenInclude(b => b.Workspace)
                .AnyAsync(bs => bs.Id == statusId && bs.Board.Workspace.UserId == userId);
                
            if (!hasAccess)
            {
                return NotFound("Status not found or access denied.");
            }

            var tasks = await _context.BoardTasks
                .Where(t => t.StatusId == statusId)
                .OrderBy(t => t.Position)
                .Select(t => new TaskDto
                {
                    Id = t.Id,
                    BoardId = t.BoardId,
                    StatusId = t.StatusId,
                    Title = t.Title,
                    Description = t.Description,
                    Priority = t.Priority,
                    DueDate = t.DueDate,
                    AssigneeId = t.AssigneeId,
                    Position = t.Position,
                    CreatedBy = t.CreatedBy,
                    Created = t.Created,
                    LastModifiedBy = t.LastModifiedBy,
                    LastModified = t.LastModified
                })
                .ToListAsync();

            return tasks;
        }

        [HttpPost("board/{boardId}")]
        public async Task<ActionResult<TaskDto>> CreateTask(int boardId, CreateTaskRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            // Verify board access and get first status
            var board = await _context.Boards
                .Include(b => b.Workspace)
                .Include(b => b.Statuses)
                .FirstOrDefaultAsync(b => b.Id == boardId && b.Workspace.UserId == userId);
                
            if (board == null)
            {
                return NotFound("Board not found or access denied.");
            }

            var firstStatus = board.Statuses.OrderBy(s => s.Position).FirstOrDefault();
            if (firstStatus == null)
            {
                return BadRequest("Board must have at least one status.");
            }

            // Get max position in the status
            var maxPosition = await _context.BoardTasks
                .Where(t => t.StatusId == firstStatus.Id)
                .Select(t => t.Position)
                .DefaultIfEmpty()
                .MaxAsync();

            var task = new BoardTask
            {
                BoardId = boardId,
                StatusId = firstStatus.Id,
                Title = request.Title,
                Description = request.Description,
                Priority = request.Priority,
                DueDate = request.DueDate,
                AssigneeId = request.AssigneeId,
                Position = maxPosition + 1
            };

            _context.BoardTasks.Add(task);
            await _context.SaveChangesAsync();

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
                Position = task.Position,
                CreatedBy = task.CreatedBy,
                Created = task.Created,
                LastModifiedBy = task.LastModifiedBy,
                LastModified = task.LastModified
            };
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<TaskDto>> UpdateTask(int id, UpdateTaskRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var task = await _context.BoardTasks
                .Include(t => t.Board)
                .ThenInclude(b => b.Workspace)
                .FirstOrDefaultAsync(t => t.Id == id && t.Board.Workspace.UserId == userId);

            if (task == null)
            {
                return NotFound();
            }

            // If status is changing, update positions
            if (request.StatusId != task.StatusId)
            {
                // Verify status belongs to the same board
                var statusExists = await _context.BoardStatuses
                    .AnyAsync(bs => bs.Id == request.StatusId && bs.BoardId == task.BoardId);
                    
                if (!statusExists)
                {
                    return BadRequest("Invalid status ID.");
                }

                // Get max position in the new status
                var maxPosition = await _context.BoardTasks
                    .Where(t => t.StatusId == request.StatusId)
                    .Select(t => t.Position)
                    .DefaultIfEmpty()
                    .MaxAsync();

                task.StatusId = request.StatusId;
                task.Position = maxPosition + 1;
            }
            else if (request.Position != task.Position)
            {
                // Update positions of other tasks in the same status
                var tasksToUpdate = await _context.BoardTasks
                    .Where(t => t.StatusId == task.StatusId && t.Id != task.Id)
                    .OrderBy(t => t.Position)
                    .ToListAsync();

                var newPosition = Math.Max(0, Math.Min(request.Position, tasksToUpdate.Count));
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

            task.Title = request.Title;
            task.Description = request.Description;
            task.Priority = request.Priority;
            task.DueDate = request.DueDate;
            task.AssigneeId = request.AssigneeId;

            await _context.SaveChangesAsync();

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
                Position = task.Position,
                CreatedBy = task.CreatedBy,
                Created = task.Created,
                LastModifiedBy = task.LastModifiedBy,
                LastModified = task.LastModified
            };
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteTask(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var task = await _context.BoardTasks
                .Include(t => t.Board)
                .ThenInclude(b => b.Workspace)
                .FirstOrDefaultAsync(t => t.Id == id && t.Board.Workspace.UserId == userId);

            if (task == null)
            {
                return NotFound();
            }

            _context.BoardTasks.Remove(task);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
} 