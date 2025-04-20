using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using CleanArchitecture.Core.DTOs.Workspace;
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
    public class WorkspaceController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public WorkspaceController(ApplicationDbContext context)
        {
            _context = context;
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

            return new WorkspaceResponse
            {
                Id = workspace.Id,
                Name = workspace.Name,
                UserId = workspace.UserId,
                CreatedBy = workspace.CreatedBy,
                Created = workspace.Created
            };
        }

        [HttpGet]
        public async Task<ActionResult<List<WorkspaceResponse>>> GetWorkspaces()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var workspaces = await _context.Workspaces
                .Where(w => w.UserId == userId)
                .Select(w => new WorkspaceResponse
                {
                    Id = w.Id,
                    Name = w.Name,
                    UserId = w.UserId,
                    CreatedBy = w.CreatedBy,
                    Created = w.Created
                })
                .ToListAsync();

            return workspaces;
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<WorkspaceResponse>> GetWorkspace(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var workspace = await _context.Workspaces
                .Where(w => w.Id == id && w.UserId == userId)
                .Select(w => new WorkspaceResponse
                {
                    Id = w.Id,
                    Name = w.Name,
                    UserId = w.UserId,
                    CreatedBy = w.CreatedBy,
                    Created = w.Created
                })
                .FirstOrDefaultAsync();

            if (workspace == null)
            {
                return NotFound();
            }

            return workspace;
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