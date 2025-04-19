using System.ComponentModel.DataAnnotations;

namespace CleanArchitecture.Core.DTOs.Workspace
{
    public class CreateWorkspaceRequest
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; }
    }
} 