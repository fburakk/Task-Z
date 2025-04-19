namespace CleanArchitecture.Core.Entities
{
    public class BoardStatus : AuditableBaseEntity
    {
        public int BoardId { get; set; }
        public string Title { get; set; }
        public int Position { get; set; }
        public virtual Board Board { get; set; }
    }
} 