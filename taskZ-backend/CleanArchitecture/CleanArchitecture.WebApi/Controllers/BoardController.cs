using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
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
    public class BoardController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public BoardController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost]
        public async Task<ActionResult<Board>> CreateBoard(CreateBoardRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            // Verify workspace exists and user has access
            var workspace = await _context.Workspaces
                .FirstOrDefaultAsync(w => w.Id == request.WorkspaceId && w.UserId == userId);
                
            if (workspace == null)
            {
                return NotFound("Workspace not found or access denied.");
            }

            var board = new Board
            {
                WorkspaceId = request.WorkspaceId,
                Name = request.Name,
                Background = request.Background ?? "#FFFFFF",
                IsArchived = false
            };

            _context.Boards.Add(board);
            await _context.SaveChangesAsync();

            return board;
        }

        [HttpGet]
        public async Task<ActionResult<List<Board>>> GetBoards([FromQuery] int workspaceId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            // Verify workspace access
            var hasAccess = await _context.Workspaces
                .AnyAsync(w => w.Id == workspaceId && w.UserId == userId);
                
            if (!hasAccess)
            {
                return NotFound("Workspace not found or access denied.");
            }

            var boards = await _context.Boards
                .Where(b => b.WorkspaceId == workspaceId && !b.IsArchived)
                .ToListAsync();

            return boards;
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Board>> GetBoard(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var board = await _context.Boards
                .Include(b => b.Workspace)
                .FirstOrDefaultAsync(b => b.Id == id && b.Workspace.UserId == userId);

            if (board == null)
            {
                return NotFound();
            }

            return board;
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateBoard(int id, UpdateBoardRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var board = await _context.Boards
                .Include(b => b.Workspace)
                .FirstOrDefaultAsync(b => b.Id == id && b.Workspace.UserId == userId);

            if (board == null)
            {
                return NotFound();
            }

            board.Name = request.Name;
            board.Background = request.Background;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        [HttpPut("{id}/archive")]
        public async Task<IActionResult> ArchiveBoard(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var board = await _context.Boards
                .Include(b => b.Workspace)
                .FirstOrDefaultAsync(b => b.Id == id && b.Workspace.UserId == userId);

            if (board == null)
            {
                return NotFound();
            }

            board.IsArchived = true;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteBoard(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var board = await _context.Boards
                .Include(b => b.Workspace)
                .FirstOrDefaultAsync(b => b.Id == id && b.Workspace.UserId == userId);

            if (board == null)
            {
                return NotFound();
            }

            _context.Boards.Remove(board);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }

    public class CreateBoardRequest
    {
        public int WorkspaceId { get; set; }
        public string Name { get; set; }
        public string Background { get; set; }
    }

    public class UpdateBoardRequest
    {
        public string Name { get; set; }
        public string Background { get; set; }
    }
} 