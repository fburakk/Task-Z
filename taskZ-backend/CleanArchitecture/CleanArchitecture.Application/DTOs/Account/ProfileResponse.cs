using System.Collections.Generic;

namespace CleanArchitecture.Core.DTOs.Account
{
    public class ProfileResponse
    {
        public string Id { get; set; }
        public string UserName { get; set; }
        public string Email { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public bool IsVerified { get; set; }
        public List<string> Roles { get; set; }
    }
} 