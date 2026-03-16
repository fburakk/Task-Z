using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using CleanArchitecture.Core.Entities;
using CleanArchitecture.Infrastructure.Contexts;
using CleanArchitecture.Infrastructure.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace CleanArchitecture.WebApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class AiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly int _recentTasksLimit;

        public AiController(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager,
            IConfiguration configuration)
        {
            _context = context;
            _userManager = userManager;
            _recentTasksLimit = int.TryParse(configuration["AiSettings:RecentTasksLimit"], out var limit) ? limit : 5;
        }

        [HttpPost("suggest-assignee")]
        public async Task<ActionResult<AssigneeContextResponse>> SuggestAssignee(SuggestAssigneeRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("uid")?.Value;

            var board = await _context.Boards
                .Include(b => b.Workspace)
                .Include(b => b.Users)
                .AsNoTracking()
                .FirstOrDefaultAsync(b => b.Id == request.BoardId &&
                    (b.Workspace.UserId == userId ||
                     b.Users.Any(u => u.UserId == userId)));

            if (board == null)
                return NotFound("Board not found or access denied.");

            var memberUserIds = board.Users.Select(u => u.UserId).ToList();

            if (!memberUserIds.Any())
                return BadRequest("Board has no members.");

            var openTaskCounts = await _context.BoardTasks
                .Where(t => t.BoardId == request.BoardId &&
                            t.AssigneeId != null &&
                            memberUserIds.Contains(t.AssigneeId))
                .GroupBy(t => t.AssigneeId)
                .Select(g => new { UserId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.UserId, x => x.Count);

            var completedEvents = await _context.TaskEvents
                .Where(e => e.BoardId == request.BoardId &&
                            e.EventType == "Completed" &&
                            e.AssigneeId != null &&
                            memberUserIds.Contains(e.AssigneeId))
                .Select(e => new
                {
                    e.AssigneeId,
                    e.Title,
                    e.Description,
                    e.AssignedAt,
                    CompletedAt = e.Created
                })
                .ToListAsync();

            var memberStats = completedEvents
                .GroupBy(e => e.AssigneeId)
                .ToDictionary(
                    g => g.Key,
                    g => new
                    {
                        CompletedCount = g.Count(),
                        AvgHours = g.Any(e => e.AssignedAt != null)
                            ? Math.Round(g.Where(e => e.AssignedAt != null)
                                .Average(e => (e.CompletedAt - e.AssignedAt.Value).TotalHours), 1)
                            : 0.0,
                        RecentTasks = g.OrderByDescending(e => e.CompletedAt)
                                        .Take(_recentTasksLimit)
                                        .Select(e => new CompletedTaskDto { Title = e.Title, Description = e.Description })
                                        .ToList()
                    });

            var members = await _userManager.Users
                .Where(u => memberUserIds.Contains(u.Id))
                .Select(u => new { u.Id, u.UserName, u.FirstName, u.LastName })
                .ToListAsync();

            var memberRole = board.Users.ToDictionary(u => u.UserId, u => u.Role);

            var memberDtos = members.Select(m =>
            {
                memberStats.TryGetValue(m.Id, out var stats);
                openTaskCounts.TryGetValue(m.Id, out var openCount);
                return new MemberContextDto
                {
                    Username = m.UserName,
                    FirstName = m.FirstName,
                    LastName = m.LastName,
                    Role = memberRole.TryGetValue(m.Id, out var role) ? role : "member",
                    CurrentOpenTasks = openCount,
                    CompletedTasksTotal = stats?.CompletedCount ?? 0,
                    AvgCompletionHours = stats?.AvgHours ?? 0,
                    RecentCompletedTasks = stats?.RecentTasks ?? new List<CompletedTaskDto>()
                };
            }).ToList();

            return Ok(new AssigneeContextResponse
            {
                Instruction = "Sen bir görev yönetim sistemi için çalışan bir yapay zeka asistanısın. Verilen göreve en uygun ekip üyesini öner.",
                ExpectedResponseFormat = new ExpectedResponseFormatDto
                {
                    RecommendedUsername = "string",
                    Reason = "kısa-açıklama"
                },
                Task = new TaskContextDto
                {
                    Title = request.Title,
                    Description = request.Description
                },
                Members = memberDtos
            });
        }
    }

    public class SuggestAssigneeRequest
    {
        public int BoardId { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
    }

    public class TaskContextDto
    {
        public string Title { get; set; }
        public string Description { get; set; }
    }

    public class MemberContextDto
    {
        public string Username { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Role { get; set; }
        public int CurrentOpenTasks { get; set; }
        public int CompletedTasksTotal { get; set; }
        public double AvgCompletionHours { get; set; }
        public List<CompletedTaskDto> RecentCompletedTasks { get; set; }
    }

    public class CompletedTaskDto
    {
        public string Title { get; set; }
        public string Description { get; set; }
    }

    public class AssigneeContextResponse
    {
        public string Instruction { get; set; }
        public ExpectedResponseFormatDto ExpectedResponseFormat { get; set; }
        public TaskContextDto Task { get; set; }
        public List<MemberContextDto> Members { get; set; }
    }

    public class ExpectedResponseFormatDto
    {
        public string RecommendedUsername { get; set; }
        public string Reason { get; set; }
    }
}
