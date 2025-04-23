using System;

namespace CleanArchitecture.Core.DTOs.Workspace
{
    public class WorkspaceResponse
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string UserId { get; set; }
        public string Username { get; set; }
        public string CreatedBy { get; set; }
        public string CreatedByUsername { get; set; }
        public DateTime Created { get; set; }
    }
} 