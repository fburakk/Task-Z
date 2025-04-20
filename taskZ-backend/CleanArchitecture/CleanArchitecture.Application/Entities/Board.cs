using System;
using System.Collections.Generic;

namespace CleanArchitecture.Core.Entities
{
    public class Board : AuditableBaseEntity
    {
        public int WorkspaceId { get; set; }
        public string Name { get; set; }
        public string Background { get; set; }
        public bool IsArchived { get; set; }
        public virtual Workspace Workspace { get; set; }
        public virtual ICollection<BoardUser> Users { get; set; }
        public virtual ICollection<BoardStatus> Statuses { get; set; }
    }
} 