namespace CleanArchitecture.Core.Entities
{
    public class Workspace : AuditableBaseEntity
    {
        public string Name { get; set; }
        public string UserId { get; set; }
    }
} 