using System;

namespace CleanArchitecture.Core.DTOs.BoardTask
{
    public class TaskDto
    {
        public int Id { get; set; }
        public int BoardId { get; set; }
        public int StatusId { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string Priority { get; set; }
        public DateTime? DueDate { get; set; }
        public string AssigneeId { get; set; }
        public string AssigneeUsername { get; set; }
        public int Position { get; set; }
        public string CreatedBy { get; set; }
        public string CreatedByUsername { get; set; }
        public DateTime Created { get; set; }
        public string LastModifiedBy { get; set; }
        public string LastModifiedByUsername { get; set; }
        public DateTime? LastModified { get; set; }
    }

    public class CreateTaskRequest
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public string Priority { get; set; }
        public DateTime? DueDate { get; set; }
        public string Username { get; set; }
        public int? StatusId { get; set; }
    }

    public class UpdateTaskRequest
    {
        public string? Title { get; set; }
        public string? Description { get; set; }
        public string? Priority { get; set; }
        public DateTime? DueDate { get; set; }
        public string? Username { get; set; }
        public int? StatusId { get; set; }
        public int? Position { get; set; }
    }
} 