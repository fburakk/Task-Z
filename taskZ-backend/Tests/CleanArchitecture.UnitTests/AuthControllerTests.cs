using AutoFixture;
using CleanArchitecture.Core.DTOs.Auth;
using CleanArchitecture.Core.Interfaces;
using CleanArchitecture.WebApi.Controllers;
using Microsoft.AspNetCore.Mvc;
using Moq;
using System.Threading.Tasks;
using Xunit;

namespace CleanArchitecture.UnitTests
{
    public class AuthControllerTests
    {
        private readonly Mock<IAuthService> _authServiceMock;
        private readonly AuthController _authController;
        private readonly Fixture _fixture;

        public AuthControllerTests()
        {
            _fixture = new Fixture();
            _authServiceMock = new Mock<IAuthService>();
            _authController = new AuthController(_authServiceMock.Object);
        }

        [Fact]
        public async Task Register_WithValidData_ShouldReturnOkResult()
        {
            // Arrange
            var request = _fixture.Create<RegisterRequest>();
            var response = _fixture.Build<AuthResponse>()
                .With(x => x.Success, true)
                .Create();

            _authServiceMock.Setup(x => x.RegisterAsync(request))
                .ReturnsAsync(response);

            // Act
            var result = await _authController.Register(request);

            // Assert
            var actionResult = Assert.IsType<ActionResult<AuthResponse>>(result);
            var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
            var returnedResponse = Assert.IsType<AuthResponse>(okResult.Value);
            Assert.True(returnedResponse.Success);
        }

        [Fact]
        public async Task Register_WithInvalidData_ShouldReturnBadRequest()
        {
            // Arrange
            var request = _fixture.Create<RegisterRequest>();
            var response = _fixture.Build<AuthResponse>()
                .With(x => x.Success, false)
                .Create();

            _authServiceMock.Setup(x => x.RegisterAsync(request))
                .ReturnsAsync(response);

            // Act
            var result = await _authController.Register(request);

            // Assert
            var actionResult = Assert.IsType<ActionResult<AuthResponse>>(result);
            var badRequestResult = Assert.IsType<BadRequestObjectResult>(actionResult.Result);
            var returnedResponse = Assert.IsType<AuthResponse>(badRequestResult.Value);
            Assert.False(returnedResponse.Success);
        }

        [Fact]
        public async Task Login_WithValidCredentials_ShouldReturnOkResult()
        {
            // Arrange
            var request = _fixture.Create<LoginRequest>();
            var response = _fixture.Build<AuthResponse>()
                .With(x => x.Success, true)
                .Create();

            _authServiceMock.Setup(x => x.LoginAsync(request))
                .ReturnsAsync(response);

            // Act
            var result = await _authController.Login(request);

            // Assert
            var actionResult = Assert.IsType<ActionResult<AuthResponse>>(result);
            var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
            var returnedResponse = Assert.IsType<AuthResponse>(okResult.Value);
            Assert.True(returnedResponse.Success);
        }

        [Fact]
        public async Task Login_WithInvalidCredentials_ShouldReturnBadRequest()
        {
            // Arrange
            var request = _fixture.Create<LoginRequest>();
            var response = _fixture.Build<AuthResponse>()
                .With(x => x.Success, false)
                .Create();

            _authServiceMock.Setup(x => x.LoginAsync(request))
                .ReturnsAsync(response);

            // Act
            var result = await _authController.Login(request);

            // Assert
            var actionResult = Assert.IsType<ActionResult<AuthResponse>>(result);
            var badRequestResult = Assert.IsType<BadRequestObjectResult>(actionResult.Result);
            var returnedResponse = Assert.IsType<AuthResponse>(badRequestResult.Value);
            Assert.False(returnedResponse.Success);
        }
    }
} 