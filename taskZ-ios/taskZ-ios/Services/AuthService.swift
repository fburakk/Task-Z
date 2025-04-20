import Foundation

class AuthService {
    private let baseURL = "http://localhost:5001/api"
    static let shared = AuthService()
    
    private init() {}
    
    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Result<AuthResponse, APIError>) -> Void) {
        let endpoint = "\(baseURL)/Auth/login"
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        let loginRequest = LoginRequest(email: email, password: password)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(loginRequest)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(APIError.handleError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    completion(.success(authResponse))
                } catch {
                    completion(.failure(.unknown("Failed to decode response: \(error.localizedDescription)")))
                }
            case 401:
                completion(.failure(.invalidCredentials))
            
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    completion(.failure(.serverError(errorResponse.message)))
                } else {
                    completion(.failure(.serverError("Bad request")))
                }
            case 500:
                completion(.failure(.serverError("Internal server error")))
            default:
                completion(.failure(.unknown("Unexpected error occurred")))
            }
        }
        task.resume()
    }
    
    // MARK: - Register
    func register(username: String, email: String, password: String, firstName: String, lastName: String, completion: @escaping (Result<AuthResponse, APIError>) -> Void) {
        let endpoint = "\(baseURL)/Auth/register"
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        let registerRequest = RegisterRequest(username: username, email: email, password: password, firstName: firstName, lastName: lastName)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(registerRequest)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(APIError.handleError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    completion(.success(authResponse))
                } catch {
                    completion(.failure(.unknown("Failed to decode response: \(error.localizedDescription)")))
                }
            case 409:
                completion(.failure(.userAlreadyExists))
            case 400:
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    completion(.failure(.serverError(errorResponse.message)))
                } else {
                    completion(.failure(.serverError("Bad request")))
                }
            case 500:
                completion(.failure(.serverError("Internal server error")))
            default:
                completion(.failure(.unknown("Unexpected error occurred")))
            }
        }
        task.resume()
    }
    
    // MARK: - Refresh Token
    func refreshToken(completion: @escaping (Result<RefreshTokenResponse, APIError>) -> Void) {
        guard let token = UserDefaultsManager.shared.authToken,
              let refreshToken = UserDefaultsManager.shared.refreshToken else {
            completion(.failure(.unauthorized))
            return
        }
        
        let endpoint = "\(baseURL)/Account/refresh-token"
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        let refreshRequest = RefreshTokenRequest(token: token, refreshToken: refreshToken)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(refreshRequest)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(APIError.handleError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let refreshResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
                    // Update stored tokens
                    UserDefaultsManager.shared.authToken = refreshResponse.jwToken
                    UserDefaultsManager.shared.refreshToken = refreshResponse.refreshToken
                    completion(.success(refreshResponse))
                } catch {
                    completion(.failure(.unknown("Failed to decode response: \(error.localizedDescription)")))
                }
            case 401:
                completion(.failure(.unauthorized))
                // Clear tokens on unauthorized
                UserDefaultsManager.shared.clearUserSession()
            default:
                completion(.failure(.unknown("Unexpected error occurred")))
            }
        }
        task.resume()
    }
} 
