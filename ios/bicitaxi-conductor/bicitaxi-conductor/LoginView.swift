//
//  LoginView.swift
//  bicitaxi-conductor
//
//  Login screen with Liquid Glass styling for conductors
//

import SwiftUI
import AuthenticationServices

/// Login view with Liquid Glass design for conductors
struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var showRegister: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                // Logo and Title
                logoSection
                
                Spacer()
                    .frame(height: 20)
                
                // Social Sign-In Buttons
                socialSignInSection
                
                // Divider
                dividerSection
                
                // Email/Password Form
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
                    .frame(height: 20)
                
                // Continue as Guest
                guestButton
                
                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BiciTaxiTheme.background)
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            // Animated Logo with Liquid Glass - Driver themed
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange, BiciTaxiTheme.accentPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                    .opacity(0.5)
                
                Image(systemName: "bicycle.circle.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(LinearGradient(
                        colors: [.orange, BiciTaxiTheme.accentPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            .glassEffect()
            .frame(width: 120, height: 120)
            
            Text("Bici Taxi")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Conductor")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(LinearGradient(
                    colors: [.orange, BiciTaxiTheme.accentPrimary],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            
            Text("Empieza a generar ingresos")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
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
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .cornerRadius(12)
            
            // Sign in with Google
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
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Divider Section
    
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)
            
            Text("o")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 16)
            
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    // MARK: - Email/Password Section
    
    private var emailPasswordSection: some View {
        VStack(spacing: 16) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Correo electrónico")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.white.opacity(0.5))
                    
                    TextField("tu@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .foregroundColor(.white)
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 12))
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.white.opacity(0.5))
                    
                    if showPassword {
                        TextField("••••••••", text: $password)
                            .foregroundColor(.white)
                    } else {
                        SecureField("••••••••", text: $password)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 12))
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
            .background(LinearGradient(
                colors: [.orange, BiciTaxiTheme.accentPrimary],
                startPoint: .leading,
                endPoint: .trailing
            ))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(authManager.isLoading)
    }
    
    // MARK: - Register Link
    
    private var registerLink: some View {
        HStack {
            Text("¿No tienes cuenta?")
                .foregroundColor(.white.opacity(0.7))
            
            Button(action: { showRegister = true }) {
                Text("Regístrate como conductor")
                    .fontWeight(.semibold)
                    .foregroundStyle(LinearGradient(
                        colors: [.orange, BiciTaxiTheme.accentPrimary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            }
        }
        .font(.subheadline)
    }
    
    // MARK: - Guest Button
    
    private var guestButton: some View {
        Button(action: {
            authManager.continueAsGuest()
        }) {
            Text("Continuar como invitado")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .underline()
        }
    }
}

#Preview {
    LoginView(authManager: AuthManager(), showRegister: .constant(false))
        .preferredColorScheme(.dark)
}
