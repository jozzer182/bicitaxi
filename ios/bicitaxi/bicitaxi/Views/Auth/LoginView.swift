//
//  LoginView.swift
//  bicitaxi
//
//  Login screen with white theme and Liquid Glass elements
//

import SwiftUI
import AuthenticationServices

/// Login view with Liquid Glass design
struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var showRegister: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Unified Color Palette
    // #0B0016, #4BB3FD, #3E6680, #0496FF, #027BCE
    
    private let primaryDark = Color(red: 0.043, green: 0, blue: 0.086)    // #0B0016
    private let accentBlue = Color(red: 0.294, green: 0.702, blue: 0.992) // #4BB3FD
    private let grayBlue = Color(red: 0.243, green: 0.4, blue: 0.502)     // #3E6680
    private let brightBlue = Color(red: 0.016, green: 0.588, blue: 1.0)   // #0496FF
    private let deepBlue = Color(red: 0.008, green: 0.482, blue: 0.808)   // #027BCE
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 20)
            
            // App Logo
            logoSection
            
            // Social Sign-In Buttons
            socialSignInSection
            
            // Divider
            dividerSection
            
            // Email/Password Form with Liquid Glass
            emailPasswordSection
            
            // Error Message
            if let error = authManager.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Login Button
            loginButton
            
            // Register Link
            registerLink
            
            Spacer()
                .frame(height: 16)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 8) {
            // App Logo from Assets with Liquid Glass frame
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 24))
                .shadow(color: deepBlue.opacity(0.2), radius: 16, x: 0, y: 8)
            
            Text("Tu viaje en bicicleta")
                .font(.subheadline)
                .foregroundColor(grayBlue)
        }
    }
    
    // MARK: - Social Sign-In Section
    
    private var socialSignInSection: some View {
        VStack(spacing: 12) {
            // Sign in with Apple
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                authManager.signInWithApple(result: result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .cornerRadius(12)
            
            // Sign in with Google with Liquid Glass
            Button(action: {
                authManager.signInWithGoogle()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "g.circle.fill")
                        .font(.title2)
                    Text("Iniciar sesión con Google")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(primaryDark)
            }
            .glassEffect(.clear.interactive().tint(accentBlue.opacity(0.3)), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Divider Section
    
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(grayBlue.opacity(0.3))
                .frame(height: 1)
            
            Text("o")
                .font(.footnote)
                .foregroundColor(grayBlue)
                .padding(.horizontal, 16)
            
            Rectangle()
                .fill(grayBlue.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    // MARK: - Email/Password Section with Liquid Glass
    
    private var emailPasswordSection: some View {
        VStack(spacing: 14) {
            // Email Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Correo electrónico")
                    .font(.footnote)
                    .foregroundColor(grayBlue)
                
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(accentBlue)
                    
                    TextField("tu@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .foregroundColor(primaryDark)
                }
                .padding()
                .glassEffect(.clear.interactive().tint(accentBlue.opacity(0.15)), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Contraseña")
                    .font(.footnote)
                    .foregroundColor(grayBlue)
                
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(accentBlue)
                    
                    if showPassword {
                        TextField("••••••••", text: $password)
                            .foregroundColor(primaryDark)
                    } else {
                        SecureField("••••••••", text: $password)
                            .foregroundColor(primaryDark)
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(grayBlue)
                    }
                }
                .padding()
                .glassEffect(.clear.interactive().tint(accentBlue.opacity(0.15)), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Login Button
    
    private var loginButton: some View {
        Button(action: {
            authManager.signIn(email: email, password: password)
        }) {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Iniciar Sesión")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(brightBlue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(authManager.isLoading)
    }
    
    // MARK: - Register Link
    
    private var registerLink: some View {
        HStack {
            Text("¿No tienes cuenta?")
                .foregroundColor(grayBlue)
            
            Button(action: { showRegister = true }) {
                Text("Regístrate")
                    .fontWeight(.semibold)
                    .foregroundColor(deepBlue)
            }
        }
        .font(.subheadline)
    }
    
}

#Preview {
    LoginView(authManager: AuthManager(), showRegister: .constant(false))
}
