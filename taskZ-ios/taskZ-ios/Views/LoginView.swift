import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var isRegisterPresented = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    Text("Welcome! Glad to see\nyou.")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 40)
                    
                    VStack(spacing: 16) {
                        ZStack(alignment: .leading) {
                            if viewModel.email.isEmpty {
                                Text("Enter your email")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 16)
                            }
                            TextField("", text: $viewModel.email)
                                .foregroundColor(.white)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 28/255, green: 28/255, blue: 30/255))
                        )
                        
                        ZStack(alignment: .leading) {
                            if viewModel.password.isEmpty {
                                Text("Enter your password")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 16)
                            }
                            SecureField("", text: $viewModel.password)
                                .foregroundColor(.white)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 28/255, green: 28/255, blue: 30/255))
                        )
                        
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                // Handle forgot password
                            }
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        }
                    }
                    
                    Button(action: {
                        viewModel.login()
                    }) {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(red: 0.5, green: 0.6, blue: 0.9))
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                        
                        NavigationLink(destination: RegisterView(), isActive: $isRegisterPresented) {
                            Button("Register Now") {
                                isRegisterPresented = true
                            }
                            .foregroundColor(.green)
                        }
                    }
                    .font(.system(size: 14))
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .cornerRadius(8)
            .foregroundColor(.white)
            .accentColor(.white)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    LoginView()
} 