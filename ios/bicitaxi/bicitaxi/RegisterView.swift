//
//  RegisterView.swift
//  bicitaxi
//
//  Registration screen with white theme and Liquid Glass elements
//

import SwiftUI

/// Registration view with Liquid Glass design
struct RegisterView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var showRegister: Bool
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var acceptTerms = false
    
    @State private var validationError: String?
    
    // MARK: - Unified Color Palette
    
    private let primaryDark = Color(red: 0.043, green: 0, blue: 0.086)    // #0B0016
    private let accentBlue = Color(red: 0.294, green: 0.702, blue: 0.992) // #4BB3FD
    private let grayBlue = Color(red: 0.243, green: 0.4, blue: 0.502)     // #3E6680
    private let brightBlue = Color(red: 0.016, green: 0.588, blue: 1.0)   // #0496FF
    private let deepBlue = Color(red: 0.008, green: 0.482, blue: 0.808)   // #027BCE
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with back button
            headerSection
            
            // Form Fields with Liquid Glass
            formSection
            
            // Error Messages
            if let error = validationError ?? authManager.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Terms and Conditions
            termsSection
            
            // Register Button
            registerButton
            
            // Login Link
            loginLink
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { showRegister = false }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(primaryDark)
                        .padding(12)
                }
                .glassEffect(.clear.interactive().tint(accentBlue.opacity(0.2)), in: Circle())
                
                Spacer()
            }
            
            // App Logo with Liquid Glass frame
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: deepBlue.opacity(0.2), radius: 12, x: 0, y: 4)
            
            Text("Crear Cuenta")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(primaryDark)
        }
    }
    
    // MARK: - Form Section with Liquid Glass
    
    private var formSection: some View {
        VStack(spacing: 12) {
            // Name Field
            fieldContainer(label: "Nombre completo", icon: "person") {
                TextField("Tu nombre", text: $name)
                    .textContentType(.name)
                    .foregroundColor(primaryDark)
            }
            
            // Email Field
            fieldContainer(label: "Correo electrónico", icon: "envelope") {
                TextField("tu@email.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .foregroundColor(primaryDark)
            }
            
            // Password Field
            fieldContainer(label: "Contraseña", icon: "lock") {
                HStack {
                    if showPassword {
                        TextField("Mínimo 8 caracteres", text: $password)
                            .foregroundColor(primaryDark)
                    } else {
                        SecureField("Mínimo 8 caracteres", text: $password)
                            .foregroundColor(primaryDark)
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(grayBlue)
                    }
                }
            }
            
            // Confirm Password Field
            fieldContainer(label: "Confirmar contraseña", icon: "lock.fill") {
                SecureField("Repite tu contraseña", text: $confirmPassword)
                    .foregroundColor(primaryDark)
            }
        }
    }
    
    // MARK: - Field Container with Liquid Glass
    
    private func fieldContainer<Content: View>(
        label: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.footnote)
                .foregroundColor(grayBlue)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(accentBlue)
                
                content()
            }
            .padding()
            .glassEffect(.clear.interactive().tint(accentBlue.opacity(0.15)), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { acceptTerms.toggle() }) {
                Image(systemName: acceptTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(acceptTerms ? brightBlue : grayBlue.opacity(0.5))
            }
            
            Text("Acepto los [Términos y Condiciones](https://example.com) y la [Política de Privacidad](https://example.com)")
                .font(.footnote)
                .foregroundColor(grayBlue)
        }
    }
    
    // MARK: - Register Button
    
    private var registerButton: some View {
        Button(action: {
            validateAndRegister()
        }) {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Crear Cuenta")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canRegister ? brightBlue : grayBlue.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canRegister || authManager.isLoading)
    }
    
    // MARK: - Login Link
    
    private var loginLink: some View {
        HStack {
            Text("¿Ya tienes cuenta?")
                .foregroundColor(grayBlue)
            
            Button(action: { showRegister = false }) {
                Text("Inicia sesión")
                    .fontWeight(.semibold)
                    .foregroundColor(deepBlue)
            }
        }
        .font(.subheadline)
    }
    
    // MARK: - Validation
    
    private var canRegister: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && 
        password == confirmPassword && acceptTerms && password.count >= 8
    }
    
    private func validateAndRegister() {
        validationError = nil
        
        if name.isEmpty {
            validationError = "Por favor ingresa tu nombre"
            return
        }
        
        if email.isEmpty || !email.contains("@") {
            validationError = "Por favor ingresa un email válido"
            return
        }
        
        if password.count < 8 {
            validationError = "La contraseña debe tener al menos 8 caracteres"
            return
        }
        
        if password != confirmPassword {
            validationError = "Las contraseñas no coinciden"
            return
        }
        
        if !acceptTerms {
            validationError = "Debes aceptar los términos y condiciones"
            return
        }
        
        authManager.register(name: name, email: email, password: password, phone: "")
    }
}

#Preview {
    RegisterView(authManager: AuthManager(), showRegister: .constant(true))
}
