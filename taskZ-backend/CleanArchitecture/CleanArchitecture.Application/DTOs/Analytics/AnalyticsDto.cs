using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace CleanArchitecture.Core.DTOs.Analytics
{
    public class AnalyticsQuery
    {
        public int? WorkspaceId { get; set; }
        public int? BoardId { get; set; }
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
        public string Category { get; set; }
    }

    public class AnalyticsOverviewResponse
    {
        public int TotalTasks { get; set; }
        public int CompletedTasks { get; set; }
        public int ActiveTasks { get; set; }
        public int OverdueTasks { get; set; }
        public int CreatedInRange { get; set; }
        public int CompletedInRange { get; set; }
        public double CompletionRate { get; set; }
        public double AverageCompletionHours { get; set; }
        public DateTime GeneratedAt { get; set; }
    }

    public class UserAnalyticsResponse
    {
        public string UserId { get; set; }
        public string Username { get; set; }
        public int AssignedTasks { get; set; }
        public int CompletedTasks { get; set; }
        public int ActiveTasks { get; set; }
        public int OverdueTasks { get; set; }
        public int CompletedInRange { get; set; }
        public double CompletionRate { get; set; }
        public double OnTimeRate { get; set; }
        public double AverageCompletionHours { get; set; }
    }

    public class UserCategoryPerformanceResponse
    {
        public string UserId { get; set; }
        public string Username { get; set; }
        public string Category { get; set; }
        public int CompletedTasks { get; set; }
        public double OnTimeRate { get; set; }
        public double AverageCompletionHours { get; set; }
        public double Score { get; set; }
        public DateTime? LastCompletedAt { get; set; }
    }

    public class TaskCategoryAuditResponse
    {
        public int TaskId { get; set; }
        public string TaskTitle { get; set; }
        public int BoardId { get; set; }
        public string BoardName { get; set; }
        public string Category { get; set; }
        public double CategoryConfidence { get; set; }
        public string AssigneeId { get; set; }
        public string AssigneeUsername { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class AssigneeRecommendationRequest
    {
        [Required]
        public int BoardId { get; set; }

        [Required]
        [StringLength(300, MinimumLength = 3)]
        public string Title { get; set; }

        public string Description { get; set; }

        [RegularExpression("^(low|medium|high)$", ErrorMessage = "Priority must be one of: low, medium, high")]
        public string Priority { get; set; } = "medium";

        public DateTime? DueDate { get; set; }
        public string WorkCategory { get; set; }

        [Range(1, 10)]
        public int TopN { get; set; } = 3;
    }

    public class AssigneeRecommendationResponse
    {
        public int BoardId { get; set; }
        public string TaskCategory { get; set; }
        public double TaskCategoryConfidence { get; set; }
        public DateTime GeneratedAt { get; set; }
        public List<AssigneeRecommendationCandidate> Candidates { get; set; } = new();
    }

    public class AssigneeRecommendationCandidate
    {
        public string UserId { get; set; }
        public string Username { get; set; }
        public double Score { get; set; }
        public RecommendationSignals Signals { get; set; }
        public List<string> Reasons { get; set; } = new();
    }

    public class RecommendationSignals
    {
        public int ActiveTasks { get; set; }
        public int OverdueActiveTasks { get; set; }
        public int CompletedTasks { get; set; }
        public double OnTimeRate { get; set; }
        public double AverageCompletionHours { get; set; }
        public double ExpertiseScore { get; set; }
        public double PriorityMatchRate { get; set; }
        public string Category { get; set; }
        public int CategoryCompletedTasks { get; set; }
        public double CategoryAverageCompletionHours { get; set; }
        public double CategoryScore { get; set; }
    }
}
