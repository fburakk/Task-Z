import Foundation

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    
    func login() {
        // Implement login logic here
        print("Login attempted with email: \(email)")
    }
} 