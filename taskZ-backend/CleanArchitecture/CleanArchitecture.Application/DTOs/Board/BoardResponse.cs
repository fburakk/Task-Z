using System;
using System.Collections.Generic;

namespace CleanArchitecture.Core.DTOs.Board
{
    public class BoardResponse
    {
        public int Id { get; set; }
        public int WorkspaceId { get; set; }
        public string Name { get; set; }
        public string Background { get; set; }
        public bool IsArchived { get; set; }
        public DateTime Created { get; set; }
        public DateTime? LastModified { get; set; }
        public List<BoardUserResponse> Users { get; set; }
        public List<BoardStatusResponse> Statuses { get; set; }
    }

    public class BoardUserResponse
    {
        public int Id { get; set; }
        public string UserId { get; set; }
        public string Username { get; set; }
        public string Role { get; set; }
    }

    public class BoardStatusResponse
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public int Position { get; set; }
    }
} 