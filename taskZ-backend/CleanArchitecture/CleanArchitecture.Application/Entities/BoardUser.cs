namespace CleanArchitecture.Core.Entities
{
    public class BoardUser : AuditableBaseEntity
    {
        public int BoardId { get; set; }
        public string UserId { get; set; }
        public string Role { get; set; }
        public virtual Board Board { get; set; }
    }
} 