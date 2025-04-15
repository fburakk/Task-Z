import Foundation

class AuthService {
    private let baseURL = "http://localhost:5001/api"
    static let shared = AuthService()
    
    private init() {}
    
    // MARK: - Login
    func login(email: String, password: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/Auth/login"
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidResponse
        }
        
        let loginRequest = LoginRequest(email: email, password: password)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(loginRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                return authResponse
            case 401:
                throw APIError.invalidCredentials
            case 400:
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.serverError(errorResponse?.message ?? "Bad request")
            case 500:
                throw APIError.serverError("Internal server error")
            default:
                throw APIError.unknown("Unexpected error occurred")
            }
        } catch {
            throw APIError.handleError(error)
        }
    }
    
    // MARK: - Register
    func register(username: String, email: String, password: String, firstName: String, lastName: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/Auth/register"
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidResponse
        }
        
        let registerRequest = RegisterRequest(username: username, email: email, password: password, firstName: firstName, lastName: lastName)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(registerRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                return authResponse
            case 409:
                throw APIError.userAlreadyExists
            case 400:
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.serverError(errorResponse?.message ?? "Bad request")
            case 500:
                throw APIError.serverError("Internal server error")
            default:
                throw APIError.unknown("Unexpected error occurred")
            }
        } catch {
            throw APIError.handleError(error)
        }
    }
    
    // MARK: - Refresh Token
    func refreshToken(token: String, refreshToken: String) async throws -> RefreshTokenResponse {
        let endpoint = "\(baseURL)/Account/refresh-token"
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidResponse
        }
        
        let refreshRequest = RefreshTokenRequest(token: token, refreshToken: refreshToken)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(refreshRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let refreshResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
                return refreshResponse
            case 401:
                throw APIError.unauthorized
            case 400:
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.serverError(errorResponse?.message ?? "Bad request")
            default:
                throw APIError.unknown("Unexpected error occurred")
            }
        } catch {
            throw APIError.handleError(error)
        }
    }
    
    // MARK: - Token Management
    private func saveTokens(token: String, refreshToken: String) {
        UserDefaults.standard.set(token, forKey: "authToken")
        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
    }
    
    func getStoredToken() -> String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    func getStoredRefreshToken() -> String? {
        return UserDefaults.standard.string(forKey: "refreshToken")
    }
    
    func clearTokens() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
    }
} 
