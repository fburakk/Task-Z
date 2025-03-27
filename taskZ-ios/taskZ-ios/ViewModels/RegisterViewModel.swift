import Foundation

class RegisterViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    func register() {
        // Implement registration logic here
        print("Registration attempted with email: \(email)")
    }
} 