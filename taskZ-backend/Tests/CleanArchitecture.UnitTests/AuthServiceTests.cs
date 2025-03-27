using AutoFixture;
using CleanArchitecture.Core.DTOs.Auth;
using CleanArchitecture.Core.Interfaces;
using CleanArchitecture.Infrastructure.Models;
using CleanArchitecture.Infrastructure.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Moq;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Xunit;

namespace CleanArchitecture.UnitTests
{
    public class AuthServiceTests
    {
        private readonly Mock<UserManager<ApplicationUser>> _userManagerMock;
        private readonly Mock<IConfiguration> _configurationMock;
        private readonly IAuthService _authService;
        private readonly Fixture _fixture;

        public AuthServiceTests()
        {
            _fixture = new Fixture();
            _userManagerMock = new Mock<UserManager<ApplicationUser>>(
                Mock.Of<IUserStore<ApplicationUser>>(), null, null, null, null, null, null, null, null);

            _configurationMock = new Mock<IConfiguration>();
            _configurationMock.Setup(x => x["JWTSettings:Key"]).Returns("TestKey123456789012345678901234567890");
            _configurationMock.Setup(x => x["JWTSettings:Issuer"]).Returns("TestIssuer");
            _configurationMock.Setup(x => x["JWTSettings:Audience"]).Returns("TestAudience");
            _configurationMock.Setup(x => x["JWTSettings:DurationInMinutes"]).Returns("60");

            _authService = new AuthService(_userManagerMock.Object, _configurationMock.Object);
        }

        [Fact]
        public async Task RegisterAsync_WithValidData_ShouldSucceed()
        {
            // Arrange
            var request = _fixture.Create<RegisterRequest>();
            var user = _fixture.Create<ApplicationUser>();
            
            _userManagerMock.Setup(x => x.FindByEmailAsync(request.Email))
                .ReturnsAsync((ApplicationUser)null);
            _userManagerMock.Setup(x => x.CreateAsync(It.IsAny<ApplicationUser>(), request.Password))
                .ReturnsAsync(IdentityResult.Success);
            _userManagerMock.Setup(x => x.GetRolesAsync(It.IsAny<ApplicationUser>()))
                .ReturnsAsync(new List<string>());

            // Act
            var result = await _authService.RegisterAsync(request);

            // Assert
            Assert.True(result.Success);
            Assert.Equal("Registration successful", result.Message);
            Assert.NotNull(result.Token);
            Assert.Equal(request.Email, result.Email);
        }

        [Fact]
        public async Task RegisterAsync_WithExistingEmail_ShouldFail()
        {
            // Arrange
            var request = _fixture.Create<RegisterRequest>();
            var existingUser = _fixture.Create<ApplicationUser>();
            
            _userManagerMock.Setup(x => x.FindByEmailAsync(request.Email))
                .ReturnsAsync(existingUser);

            // Act
            var result = await _authService.RegisterAsync(request);

            // Assert
            Assert.False(result.Success);
            Assert.Equal("Email already exists", result.Message);
            Assert.Null(result.Token);
        }

        [Fact]
        public async Task LoginAsync_WithValidCredentials_ShouldSucceed()
        {
            // Arrange
            var request = _fixture.Create<LoginRequest>();
            var user = _fixture.Build<ApplicationUser>()
                .With(x => x.Email, request.Email)
                .With(x => x.UserName, request.Email)
                .Create();
            
            _userManagerMock.Setup(x => x.FindByEmailAsync(request.Email))
                .ReturnsAsync(user);
            _userManagerMock.Setup(x => x.CheckPasswordAsync(user, request.Password))
                .ReturnsAsync(true);
            _userManagerMock.Setup(x => x.GetRolesAsync(It.IsAny<ApplicationUser>()))
                .ReturnsAsync(new List<string>());

            // Act
            var result = await _authService.LoginAsync(request);

            // Assert
            Assert.True(result.Success);
            Assert.Equal("Login successful", result.Message);
            Assert.NotNull(result.Token);
            Assert.Equal(request.Email, result.Email);
        }

        [Fact]
        public async Task LoginAsync_WithInvalidCredentials_ShouldFail()
        {
            // Arrange
            var request = _fixture.Create<LoginRequest>();
            var user = _fixture.Create<ApplicationUser>();
            
            _userManagerMock.Setup(x => x.FindByEmailAsync(request.Email))
                .ReturnsAsync(user);
            _userManagerMock.Setup(x => x.CheckPasswordAsync(user, request.Password))
                .ReturnsAsync(false);

            // Act
            var result = await _authService.LoginAsync(request);

            // Assert
            Assert.False(result.Success);
            Assert.Equal("Invalid email or password", result.Message);
            Assert.Null(result.Token);
        }

        [Fact]
        public async Task LoginAsync_WithNonExistentEmail_ShouldFail()
        {
            // Arrange
            var request = _fixture.Create<LoginRequest>();
            
            _userManagerMock.Setup(x => x.FindByEmailAsync(request.Email))
                .ReturnsAsync((ApplicationUser)null);

            // Act
            var result = await _authService.LoginAsync(request);

            // Assert
            Assert.False(result.Success);
            Assert.Equal("Invalid email or password", result.Message);
            Assert.Null(result.Token);
        }
    }
} 