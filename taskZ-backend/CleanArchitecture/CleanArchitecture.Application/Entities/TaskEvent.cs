using System;

namespace CleanArchitecture.Core.Entities
{
    public class TaskEvent : AuditableBaseEntity
    {
        public int TaskId { get; set; }
        public int BoardId { get; set; }
        public int WorkspaceId { get; set; }
        public string EventType { get; set; }
        public string ActorUserId { get; set; }
        public int? StatusId { get; set; }
        public int? FromStatusId { get; set; }
        public int? ToStatusId { get; set; }
        public string AssigneeId { get; set; }
        public string FromAssigneeId { get; set; }
        public string ToAssigneeId { get; set; }
        public DateTime? AssignedAt { get; set; }  // Snapshot of BoardTask.AssignedAt at Completed time
        public string Priority { get; set; }
        public DateTime? DueDate { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string Metadata { get; set; }
    }
}
