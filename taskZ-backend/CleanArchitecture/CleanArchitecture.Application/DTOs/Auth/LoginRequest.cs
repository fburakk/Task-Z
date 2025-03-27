using System.ComponentModel.DataAnnotations;

namespace CleanArchitecture.Core.DTOs.Auth
{
    public class LoginRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        public string Password { get; set; }
    }
} 