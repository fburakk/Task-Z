namespace CleanArchitecture.Core.DTOs.Auth
{
    public class AuthResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public string Token { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
    }
} 