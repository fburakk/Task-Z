using System.ComponentModel.DataAnnotations;

namespace CleanArchitecture.Core.DTOs.Board
{
    public class CreateBoardRequest
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; }

        [Required]
        [RegularExpression("^#[0-9A-Fa-f]{6}$", ErrorMessage = "Background must be a valid hex color (e.g. #FFAA00)")]
        public string Background { get; set; }
    }
} 