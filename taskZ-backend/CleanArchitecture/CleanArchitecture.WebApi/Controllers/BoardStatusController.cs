using System.Threading.Tasks;
using System.Linq;
using System.Collections.Generic;
using CleanArchitecture.Core.Entities;
using CleanArchitecture.Core.DTOs.Board;
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
    public class BoardStatusController : ControllerBase
    {
        private static readonly HashSet<string> AllowedStatusTypes = new HashSet<string>
        {
            BoardStatus.Todo,
            BoardStatus.InProgress,
            BoardStatus.Custom,
            BoardStatus.Done
        };

        private readonly ApplicationDbContext _context;

        public BoardStatusController(ApplicationDbContext context)
        {
            _context = context;
        }

        private static string NormalizeType(string type)
        {
            return string.IsNullOrWhiteSpace(type)
                ? BoardStatus.Custom
                : type.Trim().ToLowerInvariant();
        }

        [HttpPost]
        public async Task<ActionResult<BoardStatusResponse>> CreateStatus([FromBody] CreateStatusRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("uid")?.Value;
            var type = NormalizeType(request.Type);

            if (string.IsNullOrWhiteSpace(request.Name))
            {
                return BadRequest("Status name is required.");
            }

            if (!AllowedStatusTypes.Contains(type))
            {
                return BadRequest("Invalid status type.");
            }
            
            // Verify board access
            var board = await _context.Boards
                .Include(b => b.Workspace)
                .Include(b => b.Users)
                .FirstOrDefaultAsync(b => b.Id == request.BoardId && 
                    (b.Workspace.UserId == userId || // Workspace owner
                     b.Users.Any(u => u.UserId == userId))); // Board member
                
            if (board == null)
            {
                return NotFound("Board not found or insufficient permissions.");
            }

            if (type == BoardStatus.Todo || type == BoardStatus.Done)
            {
                var existsSameType = await _context.BoardStatuses
                    .AnyAsync(s => s.BoardId == request.BoardId && s.Type == type);

                if (existsSameType)
                {
                    return BadRequest($"Board already has a '{type}' status.");
                }
            }

            // Get max position
            var maxPosition = await _context.BoardStatuses
                .Where(s => s.BoardId == request.BoardId)
                .Select(s => s.Position)
                .DefaultIfEmpty()
                .MaxAsync();

            var status = new BoardStatus
            {
                BoardId = request.BoardId,
                Title = request.Name.Trim(),
                Type = type,
                Position = maxPosition + 1
            };

            _context.BoardStatuses.Add(status);
            await _context.SaveChangesAsync();

            return new BoardStatusResponse
            {
                Id = status.Id,
                Title = status.Title,
                Type = status.Type,
                Position = status.Position
            };
        }

        [HttpPut("{id:int}")]
        public async Task<ActionResult<BoardStatusResponse>> UpdateStatus(int id, [FromBody] UpdateStatusRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("uid")?.Value;
            if (string.IsNullOrWhiteSpace(request?.Name))
            {
                return BadRequest("Status name is required.");
            }

            var status = await _context.BoardStatuses
                .Include(s => s.Board)
                .ThenInclude(b => b.Workspace)
                .Include(s => s.Board)
                .ThenInclude(b => b.Users)
                .FirstOrDefaultAsync(s => s.Id == id &&
                    (s.Board.Workspace.UserId == userId ||
                     s.Board.Users.Any(u => u.UserId == userId)));

            if (status == null)
            {
                return NotFound("Status not found or insufficient permissions.");
            }

            status.Title = request.Name.Trim();
            await _context.SaveChangesAsync();

            return new BoardStatusResponse
            {
                Id = status.Id,
                Title = status.Title,
                Type = status.Type,
                Position = status.Position
            };
        }

        [HttpPut("reorder")]
        public async Task<IActionResult> ReorderStatuses([FromBody] ReorderStatusesRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("uid")?.Value;
            if (request == null || request.BoardId <= 0 || request.StatusIds == null || request.StatusIds.Count == 0)
            {
                return BadRequest("BoardId and statusIds are required.");
            }

            if (request.StatusIds.Count != request.StatusIds.Distinct().Count())
            {
                return BadRequest("Duplicate status ids are not allowed.");
            }

            var board = await _context.Boards
                .Include(b => b.Workspace)
                .Include(b => b.Users)
                .Include(b => b.Statuses)
                .FirstOrDefaultAsync(b => b.Id == request.BoardId &&
                    (b.Workspace.UserId == userId ||
                     b.Users.Any(u => u.UserId == userId)));

            if (board == null)
            {
                return NotFound("Board not found or insufficient permissions.");
            }

            var currentStatusIds = board.Statuses.Select(s => s.Id).ToList();
            var requestedStatusIds = request.StatusIds.ToList();
            var hasMismatch =
                requestedStatusIds.Count != currentStatusIds.Count ||
                requestedStatusIds.Except(currentStatusIds).Any() ||
                currentStatusIds.Except(requestedStatusIds).Any();

            if (hasMismatch)
            {
                return BadRequest("Status list does not match board statuses.");
            }

            var statusById = board.Statuses.ToDictionary(s => s.Id, s => s);
            for (var index = 0; index < requestedStatusIds.Count; index++)
            {
                statusById[requestedStatusIds[index]].Position = index;
            }

            await _context.SaveChangesAsync();
            return NoContent();
        }
    }

    public class CreateStatusRequest
    {
        public int BoardId { get; set; }
        public string Name { get; set; }
        public string Type { get; set; } = BoardStatus.Custom;
    }

    public class UpdateStatusRequest
    {
        public string Name { get; set; }
    }

    public class ReorderStatusesRequest
    {
        public int BoardId { get; set; }
        public List<int> StatusIds { get; set; } = new List<int>();
    }
} 
