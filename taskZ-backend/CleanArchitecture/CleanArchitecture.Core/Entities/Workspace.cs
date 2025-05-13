using System.Collections.Generic;

namespace CleanArchitecture.Core.Entities
{
    public class Workspace : AuditableBaseEntity
    {
        public string Name { get; set; }
        public string UserId { get; set; }
        public virtual ICollection<Board> Boards { get; set; }
    }
} 