using System.ComponentModel.DataAnnotations;

namespace CleanArchitecture.Core.DTOs.Board
{
    public class AddBoardUserRequest
    {
        [Required]
        public string Username { get; set; }

        [Required]
        [RegularExpression("^(editor|viewer)$", ErrorMessage = "Role must be either 'editor' or 'viewer'")]
        public string Role { get; set; }
    }
} 