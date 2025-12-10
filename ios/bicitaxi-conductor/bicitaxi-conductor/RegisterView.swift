//
//  RegisterView.swift
//  bicitaxi-conductor
//
//  Registration screen for conductors with Liquid Glass styling
//

import SwiftUI

/// Registration view for conductors with Liquid Glass design
struct RegisterView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var showRegister: Bool
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var licenseNumber = ""
    @State private var vehicleInfo = ""
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
    
    // MARK: - Gradient
    
    private var conductorGradient: LinearGradient {
        LinearGradient(
            colors: [.orange, BiciTaxiTheme.accentPrimary],
            startPoint: .leading,
            endPoint: .trailing
        )
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
            
            Text("Registro Conductor")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Únete a nuestro equipo")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 16) {
            // Personal Info Section
            Text("Información Personal")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
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
            
            // Driver Info Section
            Text("Información del Conductor")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            
            // License Number Field
            fieldContainer(label: "Número de Licencia", icon: "creditcard") {
                TextField("ABC123456", text: $licenseNumber)
                    .foregroundColor(.white)
                    .autocapitalization(.allCharacters)
            }
            
            // Vehicle Info Field
            fieldContainer(label: "Información del Vehículo (opcional)", icon: "bicycle") {
                TextField("Ej: Bicicleta roja con canasta", text: $vehicleInfo)
                    .foregroundColor(.white)
            }
            
            // Security Section
            Text("Seguridad")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            
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
                    .foregroundStyle(acceptTerms ? AnyShapeStyle(conductorGradient) : AnyShapeStyle(.white.opacity(0.5)))
            }
            
            Text("Acepto los [Términos para Conductores](https://example.com) y la [Política de Privacidad](https://example.com)")
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
                    Text("Registrarme como Conductor")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canRegister ? AnyShapeStyle(conductorGradient) : AnyShapeStyle(.gray.opacity(0.5)))
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
                    .foregroundStyle(conductorGradient)
            }
        }
        .font(.subheadline)
    }
    
    // MARK: - Validation
    
    private var canRegister: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && 
        password == confirmPassword && acceptTerms && password.count >= 8 &&
        !licenseNumber.isEmpty
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
        
        if licenseNumber.isEmpty {
            validationError = "Por favor ingresa tu número de licencia"
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
        
        authManager.register(name: name, email: email, password: password, phone: phone, licenseNumber: licenseNumber)
    }
}

#Preview {
    RegisterView(authManager: AuthManager(), showRegister: .constant(true))
        .preferredColorScheme(.dark)
}
