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

        private async Task<BoardResponse> MapToBoardResponse(Board board)
        {
            var createdByUser = await _userManager.FindByIdAsync(board.CreatedBy);
            var lastModifiedByUser = board.LastModifiedBy != null ? await _userManager.FindByIdAsync(board.LastModifiedBy) : null;

            var users = await _context.BoardUsers
                .Where(u => u.BoardId == board.Id)
                .Join(_userManager.Users,
                    bu => bu.UserId,
                    user => user.Id,
                    (bu, user) => new BoardUserResponse
                    {
                        Id = bu.Id,
                        UserId = bu.UserId,
                        Username = user.UserName,
                        Role = bu.Role
                    })
                .ToListAsync();

            var statuses = await _context.BoardStatuses
                .Where(s => s.BoardId == board.Id)
                .OrderBy(s => s.Position)
                .Select(s => new BoardStatusResponse
                {
                    Id = s.Id,
                    Title = s.Title,
                    Position = s.Position
                })
                .ToListAsync();

            return new BoardResponse
            {
                Id = board.Id,
                WorkspaceId = board.WorkspaceId,
                Name = board.Name,
                Background = board.Background,
                IsArchived = board.IsArchived,
                CreatedBy = board.CreatedBy,
                CreatedByUsername = createdByUser?.UserName,
                Created = board.Created,
                LastModifiedBy = board.LastModifiedBy,
                LastModifiedByUsername = lastModifiedByUser?.UserName,
                LastModified = board.LastModified,
                Users = users,
                Statuses = statuses
            };
        }

        [HttpPost]
        public async Task<ActionResult<BoardResponse>> CreateBoard(CreateBoardRequest request)
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

            return await MapToBoardResponse(board);
        }

        [HttpGet]
        public async Task<ActionResult<List<BoardResponse>>> GetBoards([FromQuery] int workspaceId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            // Get workspace owner's boards and boards where user is a member
            var boards = await _context.Boards
                .AsNoTracking()
                .Include(b => b.Workspace)
                .Include(b => b.Users)
                .Where(b => b.WorkspaceId == workspaceId && 
                    !b.IsArchived &&
                    (b.Workspace.UserId == userId || // Workspace owner
                     b.Users.Any(u => u.UserId == userId))) // Board member
                .ToListAsync();

            var responses = new List<BoardResponse>();
            foreach (var board in boards)
            {
                responses.Add(await MapToBoardResponse(board));
            }

            return responses;
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<BoardResponse>> GetBoard(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var board = await _context.Boards
                .AsNoTracking()
                .Include(b => b.Workspace)
                .Include(b => b.Users)
                .FirstOrDefaultAsync(b => b.Id == id && 
                    (b.Workspace.UserId == userId || // Workspace owner
                     b.Users.Any(u => u.UserId == userId))); // Board member

            if (board == null)
            {
                return NotFound();
            }

            return await MapToBoardResponse(board);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateBoard(int id, UpdateBoardRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var board = await _context.Boards
                .Include(b => b.Workspace)
                .Include(b => b.Users)
                .AsTracking()
                .FirstOrDefaultAsync(b => b.Id == id && 
                    (b.Workspace.UserId == userId || // Workspace owner
                     b.Users.Any(u => u.UserId == userId && u.Role == "editor"))); // Board editor

            if (board == null)
            {
                return NotFound("Board not found or insufficient permissions.");
            }

            board.Name = request.Name;
            board.Background = request.Background;
            
            _context.Boards.Update(board);
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
                .Include(b => b.Users)
                .AnyAsync(b => b.Id == id && 
                    (b.Workspace.UserId == userId || // Workspace owner
                     b.Users.Any(u => u.UserId == userId))); // Board member
                
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
                .Include(u => u.Board)
                .Where(u => u.BoardId == id)
                .Join(_userManager.Users,
                    bu => bu.UserId,
                    user => user.Id,
                    (bu, user) => new BoardUserResponse
                    {
                        Id = bu.Id,
                        UserId = bu.UserId,
                        Username = user.UserName,
                        Role = bu.Role
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