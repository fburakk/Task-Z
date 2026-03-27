using System;

namespace CleanArchitecture.Core.Entities
{
    public class UserCategoryScore
    {
        public int Id { get; set; }
        public string UserId { get; set; }
        public string Category { get; set; }
        public int CompletedTasks { get; set; }
        public int OnTimeCompletedTasks { get; set; }
        public double TotalCompletionHours { get; set; }
        public double AverageCompletionHours { get; set; }
        public double Score { get; set; }
        public DateTime? LastCompletedAt { get; set; }
        public int? LastTaskId { get; set; }
    }
}
