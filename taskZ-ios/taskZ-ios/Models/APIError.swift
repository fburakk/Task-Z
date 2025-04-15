import Foundation

enum APIError: LocalizedError {
    case invalidCredentials
    case userAlreadyExists
    case networkError
    case serverError(String)
    case invalidResponse
    case unauthorized
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .userAlreadyExists:
            return "A user with this email already exists."
        case .networkError:
            return "Unable to connect to the server. Please check your internet connection."
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidResponse:
            return "Invalid response from server."
        case .unauthorized:
            return "Your session has expired. Please login again."
        case .unknown(let message):
            return message
        }
    }
    
    static func handleError(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }
        
        // Handle network errors
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return .networkError
            default:
                return .unknown("Network error: \(error.localizedDescription)")
            }
        }
        
        return .unknown(error.localizedDescription)
    }
} 