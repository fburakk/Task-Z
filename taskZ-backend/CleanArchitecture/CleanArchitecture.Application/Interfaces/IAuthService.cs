using CleanArchitecture.Core.DTOs.Auth;
using System.Threading.Tasks;

namespace CleanArchitecture.Core.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponse> RegisterAsync(RegisterRequest request);
        Task<AuthResponse> LoginAsync(LoginRequest request);
    }
} 