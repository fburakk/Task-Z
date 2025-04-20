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
    public class BoardStatusController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public BoardStatusController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost]
        public async Task<ActionResult<BoardStatus>> CreateStatus([FromBody] CreateStatusRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            // Verify board access
            var board = await _context.Boards
                .Include(b => b.Workspace)
                .FirstOrDefaultAsync(b => b.Id == request.BoardId && b.Workspace.UserId == userId);
                
            if (board == null)
            {
                return NotFound("Board not found or access denied.");
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
                Title = request.Name,
                Position = maxPosition + 1
            };

            _context.BoardStatuses.Add(status);
            await _context.SaveChangesAsync();

            return status;
        }
    }

    public class CreateStatusRequest
    {
        public int BoardId { get; set; }
        public string Name { get; set; }
    }
} 