import Foundation

// MARK: - Request Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
    let firstName: String
    let lastName: String
}

// MARK: - Response Models
struct AuthResponse: Codable {
    let success: Bool
    let message: String
    let token: String
    let refreshToken: String
    let username: String
    let email: String
}

struct RefreshTokenRequest: Codable {
    let token: String
    let refreshToken: String
}

struct RefreshTokenResponse: Codable {
    let id: String
    let userName: String
    let email: String
    let roles: [String]
    let isVerified: Bool
    let jwToken: String
    let refreshToken: String
}

// MARK: - Error Model
struct ErrorResponse: Codable {
    let success: Bool
    let message: String
    let errors: [String]?
} 