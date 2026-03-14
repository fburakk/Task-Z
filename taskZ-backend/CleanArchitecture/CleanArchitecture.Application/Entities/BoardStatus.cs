namespace CleanArchitecture.Core.Entities
{
    public class BoardStatus : AuditableBaseEntity
    {
        public const string Todo = "todo";
        public const string InProgress = "in_progress";
        public const string Custom = "custom";
        public const string Done = "done";

        public int BoardId { get; set; }
        public string Title { get; set; }
        public string Type { get; set; } = Custom;
        public int Position { get; set; }
        public virtual Board Board { get; set; }
    }
}
