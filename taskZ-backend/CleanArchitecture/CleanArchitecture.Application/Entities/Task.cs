using System;

namespace CleanArchitecture.Core.Entities
{
    public class BoardTask : AuditableBaseEntity
    {
        public int BoardId { get; set; }
        public int StatusId { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string Priority { get; set; }  // "low", "medium", "high"
        public DateTime? DueDate { get; set; }
        public string AssigneeId { get; set; }  // User ID from Identity
        public int Position { get; set; }

        // Navigation properties
        public virtual Board Board { get; set; }
        public virtual BoardStatus Status { get; set; }
    }
} 