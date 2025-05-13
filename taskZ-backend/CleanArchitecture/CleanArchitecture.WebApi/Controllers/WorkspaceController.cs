using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using CleanArchitecture.Core.DTOs.Workspace;
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
    public class WorkspaceController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public WorkspaceController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        private async Task<WorkspaceResponse> MapToWorkspaceResponse(Workspace workspace)
        {
            var user = await _userManager.FindByIdAsync(workspace.UserId);
            var createdByUser = await _userManager.FindByIdAsync(workspace.CreatedBy);

            return new WorkspaceResponse
            {
                Id = workspace.Id,
                Name = workspace.Name,
                UserId = workspace.UserId,
                Username = user?.UserName,
                CreatedBy = workspace.CreatedBy,
                CreatedByUsername = createdByUser?.UserName,
                Created = workspace.Created
            };
        }

        [HttpPost]
        public async Task<ActionResult<WorkspaceResponse>> CreateWorkspace(CreateWorkspaceRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var workspace = new Workspace
            {
                Name = request.Name,
                UserId = userId
            };

            _context.Workspaces.Add(workspace);
            await _context.SaveChangesAsync();

            return await MapToWorkspaceResponse(workspace);
        }

        [HttpGet]
        public async Task<ActionResult<List<WorkspaceResponse>>> GetWorkspaces()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            // First get all board IDs where the user is a member
            var boardIds = await _context.BoardUsers
                .Where(bu => bu.UserId == userId)
                .Select(bu => bu.BoardId)
                .ToListAsync();

            // Then get all workspaces where user is either owner or has boards
            var workspaces = await _context.Workspaces
                .Include(w => w.Boards.Where(b => !b.IsArchived))
                    .ThenInclude(b => b.Users)
                .Where(w => w.UserId == userId || // User owns the workspace
                           w.Boards.Any(b => boardIds.Contains(b.Id))) // User is a member of any board
                .AsSplitQuery()
                .Distinct()
                .ToListAsync();

            var responses = new List<WorkspaceResponse>();
            foreach (var workspace in workspaces)
            {
                responses.Add(await MapToWorkspaceResponse(workspace));
            }

            return responses;
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<WorkspaceResponse>> GetWorkspace(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var workspace = await _context.Workspaces
                .FirstOrDefaultAsync(w => w.Id == id && w.UserId == userId);

            if (workspace == null)
            {
                return NotFound();
            }

            return await MapToWorkspaceResponse(workspace);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateWorkspace(int id, CreateWorkspaceRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var workspace = await _context.Workspaces
                .FirstOrDefaultAsync(w => w.Id == id && w.UserId == userId);

            if (workspace == null)
            {
                return NotFound();
            }

            workspace.Name = request.Name;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteWorkspace(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var workspace = await _context.Workspaces
                .FirstOrDefaultAsync(w => w.Id == id && w.UserId == userId);

            if (workspace == null)
            {
                return NotFound();
            }

            _context.Workspaces.Remove(workspace);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
} 