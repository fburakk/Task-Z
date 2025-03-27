import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                Text("Let's Register!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 40)
                
                VStack(spacing: 16) {
                    ZStack(alignment: .leading) {
                        if viewModel.username.isEmpty {
                            Text("Enter username")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                        }
                        TextField("", text: $viewModel.username)
                            .foregroundColor(.white)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.none)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 28/255, green: 28/255, blue: 30/255))
                    )
                    
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
                            Text("Create password")
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
                    
                    ZStack(alignment: .leading) {
                        if viewModel.confirmPassword.isEmpty {
                            Text("Confirm password")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                        }
                        SecureField("", text: $viewModel.confirmPassword)
                            .foregroundColor(.white)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 28/255, green: 28/255, blue: 30/255))
                    )
                }
                
                Button(action: {
                    viewModel.register()
                }) {
                    Text("Agree and Register")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 0.5, green: 0.6, blue: 0.9))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
        })
    }
}

#Preview {
    RegisterView()
} 