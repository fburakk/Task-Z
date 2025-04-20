using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using CleanArchitecture.Core.Entities;
using CleanArchitecture.Infrastructure.Contexts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using CleanArchitecture.Core.DTOs.Board;
using Microsoft.AspNetCore.Identity;
using CleanArchitecture.Infrastructure.Models;

namespace CleanArchitecture.WebApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class BoardController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public BoardController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
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
                .AsNoTracking()
                .AnyAsync(w => w.Id == workspaceId && w.UserId == userId);
                
            if (!hasAccess)
            {
                return NotFound("Workspace not found or access denied.");
            }

            var boards = await _context.Boards
                .AsNoTracking()
                .Where(b => b.WorkspaceId == workspaceId && !b.IsArchived)
                .ToListAsync();

            return boards;
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Board>> GetBoard(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var board = await _context.Boards
                .AsNoTracking()  // Explicitly state no tracking for read-only operation
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
                .AsTracking()  // Enable tracking for this query
                .FirstOrDefaultAsync(b => b.Id == id && b.Workspace.UserId == userId);

            if (board == null)
            {
                return NotFound();
            }

            board.Name = request.Name;
            board.Background = request.Background;
            
            _context.Boards.Update(board);  // Explicitly mark the entity as modified
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

        [HttpGet("{id}/statuses")]
        public async Task<ActionResult<List<BoardStatusResponse>>> GetBoardStatuses(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            // Verify board access
            var hasAccess = await _context.Boards
                .Include(b => b.Workspace)
                .AnyAsync(b => b.Id == id && b.Workspace.UserId == userId);
                
            if (!hasAccess)
            {
                return NotFound("Board not found or access denied.");
            }

            var statuses = await _context.BoardStatuses
                .Where(s => s.BoardId == id)
                .OrderBy(s => s.Position)
                .Select(s => new BoardStatusResponse
                {
                    Id = s.Id,
                    Title = s.Title,
                    Position = s.Position
                })
                .ToListAsync();

            return statuses;
        }

        [HttpGet("{id}/users")]
        public async Task<ActionResult<List<BoardUserResponse>>> GetBoardUsers(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            // Verify board access
            var hasAccess = await _context.Boards
                .Include(b => b.Workspace)
                .AnyAsync(b => b.Id == id && b.Workspace.UserId == userId);
                
            if (!hasAccess)
            {
                return NotFound("Board not found or access denied.");
            }

            var users = await _context.BoardUsers
                .Where(u => u.BoardId == id)
                .Select(u => new BoardUserResponse
                {
                    Id = u.Id,
                    UserId = u.UserId,
                    Username = u.UserId, // TODO: Join with AspNetUsers to get actual username
                    Role = u.Role
                })
                .ToListAsync();

            return users;
        }

        [HttpPost("{id}/users")]
        public async Task<ActionResult<BoardUserResponse>> AddBoardUser(int id, AddBoardUserRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            // Verify board access
            var board = await _context.Boards
                .Include(b => b.Workspace)
                .FirstOrDefaultAsync(b => b.Id == id && b.Workspace.UserId == userId);
                
            if (board == null)
            {
                return NotFound("Board not found or access denied.");
            }

            // Find user by username
            var userToAdd = await _userManager.FindByNameAsync(request.Username);
            if (userToAdd == null)
            {
                return NotFound($"User '{request.Username}' not found.");
            }

            // Check if user is already added to the board
            var existingBoardUser = await _context.BoardUsers
                .FirstOrDefaultAsync(bu => bu.BoardId == id && bu.UserId == userToAdd.Id);
                
            if (existingBoardUser != null)
            {
                return BadRequest($"User '{request.Username}' is already added to this board.");
            }

            var boardUser = new BoardUser
            {
                BoardId = id,
                UserId = userToAdd.Id,
                Role = request.Role
            };

            _context.BoardUsers.Add(boardUser);
            await _context.SaveChangesAsync();

            return new BoardUserResponse
            {
                Id = boardUser.Id,
                UserId = boardUser.UserId,
                Username = request.Username,
                Role = boardUser.Role
            };
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