import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let isLoggedIn = "isLoggedIn"
        static let authToken = "authToken"
        static let refreshToken = "refreshToken"
        static let username = "username"
        static let email = "email"
    }
    
    private init() {}
    
    // MARK: - Session Management
    var isLoggedIn: Bool {
        get {
            defaults.bool(forKey: Keys.isLoggedIn)
        }
        set {
            defaults.set(newValue, forKey: Keys.isLoggedIn)
        }
    }
    
    var authToken: String? {
        get {
            defaults.string(forKey: Keys.authToken)
        }
        set {
            defaults.set(newValue, forKey: Keys.authToken)
        }
    }
    
    var refreshToken: String? {
        get {
            defaults.string(forKey: Keys.refreshToken)
        }
        set {
            defaults.set(newValue, forKey: Keys.refreshToken)
        }
    }
    
    var username: String? {
        get {
            defaults.string(forKey: Keys.username)
        }
        set {
            defaults.set(newValue, forKey: Keys.username)
        }
    }
    
    var email: String? {
        get {
            defaults.string(forKey: Keys.email)
        }
        set {
            defaults.set(newValue, forKey: Keys.email)
        }
    }
    
    func saveUserSession(authResponse: AuthResponse) {
        isLoggedIn = true
        authToken = authResponse.token
        refreshToken = authResponse.refreshToken
        username = authResponse.username
        email = authResponse.email
    }
    
    func clearUserSession() {
        isLoggedIn = false
        authToken = nil
        refreshToken = nil
        username = nil
        email = nil
    }
}
