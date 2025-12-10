//
//  RegisterView.swift
//  bicitaxi
//
//  Registration screen with Liquid Glass styling
//

import SwiftUI

/// Registration view with Liquid Glass design
struct RegisterView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var showRegister: Bool
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var acceptTerms = false
    
    @State private var validationError: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)
                
                // Header with back button
                headerSection
                
                // Form Fields
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
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BiciTaxiTheme.background)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { showRegister = false }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .glassEffect()
                }
                
                Spacer()
            }
            
            Text("Crear Cuenta")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Únete a Bici Taxi")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 16) {
            // Name Field
            fieldContainer(label: "Nombre completo", icon: "person") {
                TextField("Tu nombre", text: $name)
                    .textContentType(.name)
                    .foregroundColor(.white)
            }
            
            // Email Field
            fieldContainer(label: "Correo electrónico", icon: "envelope") {
                TextField("tu@email.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .foregroundColor(.white)
            }
            
            // Phone Field
            fieldContainer(label: "Teléfono", icon: "phone") {
                TextField("+52 123 456 7890", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .foregroundColor(.white)
            }
            
            // Password Field
            fieldContainer(label: "Contraseña", icon: "lock") {
                HStack {
                    if showPassword {
                        TextField("Mínimo 8 caracteres", text: $password)
                            .foregroundColor(.white)
                    } else {
                        SecureField("Mínimo 8 caracteres", text: $password)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            
            // Confirm Password Field
            fieldContainer(label: "Confirmar contraseña", icon: "lock.fill") {
                SecureField("Repite tu contraseña", text: $confirmPassword)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Field Container
    
    private func fieldContainer<Content: View>(
        label: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.5))
                
                content()
            }
            .padding()
            .glassEffect(in: .rect(cornerRadius: 12))
        }
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { acceptTerms.toggle() }) {
                Image(systemName: acceptTerms ? "checkmark.square.fill" : "square")
                    .foregroundStyle(acceptTerms ? AnyShapeStyle(BiciTaxiTheme.accentGradient) : AnyShapeStyle(.white.opacity(0.5)))
            }
            
            Text("Acepto los [Términos y Condiciones](https://example.com) y la [Política de Privacidad](https://example.com)")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
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
            .background(canRegister ? AnyShapeStyle(BiciTaxiTheme.accentGradient) : AnyShapeStyle(.gray.opacity(0.5)))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canRegister || authManager.isLoading)
    }
    
    // MARK: - Login Link
    
    private var loginLink: some View {
        HStack {
            Text("¿Ya tienes cuenta?")
                .foregroundColor(.white.opacity(0.7))
            
            Button(action: { showRegister = false }) {
                Text("Inicia sesión")
                    .fontWeight(.semibold)
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
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
        
        authManager.register(name: name, email: email, password: password, phone: phone)
    }
}

#Preview {
    RegisterView(authManager: AuthManager(), showRegister: .constant(true))
        .preferredColorScheme(.dark)
}
