//
//  ChangePasswordSheet.swift
//  bicitaxi
//
//  Password change sheet with validation
//

import SwiftUI

struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var isSaving = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    
    private var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty && !newPassword.isEmpty && passwordsMatch && newPassword.count >= 6
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header icon
                    headerIcon
                    
                    // Current password field
                    passwordField(
                        title: "Contraseña Actual",
                        text: $currentPassword,
                        isVisible: $showCurrentPassword,
                        icon: "key.fill"
                    )
                    
                    // New password field
                    passwordField(
                        title: "Nueva Contraseña",
                        text: $newPassword,
                        isVisible: $showNewPassword,
                        icon: "key.badge.plus.fill"
                    )
                    
                    // Confirm password field
                    passwordField(
                        title: "Confirmar Contraseña",
                        text: $confirmPassword,
                        isVisible: $showConfirmPassword,
                        icon: "checkmark.shield.fill"
                    )
                    
                    // Validation messages
                    validationMessages
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Save button
                    saveButton
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
            .scrollContentBackground(.hidden)
            .background(BiciTaxiTheme.background.ignoresSafeArea())
            .navigationTitle("Cambiar Contraseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(BiciTaxiTheme.accentPrimary)
                }
            }
            .alert("Contraseña Actualizada", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Tu contraseña ha sido cambiada correctamente.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Header Icon
    
    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(BiciTaxiTheme.accentPrimary.opacity(0.15))
                .frame(width: 80, height: 80)
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 36))
                .foregroundColor(BiciTaxiTheme.accentPrimary)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Password Field
    
    private func passwordField(
        title: String,
        text: Binding<String>,
        isVisible: Binding<Bool>,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(BiciTaxiTheme.accentPrimary)
                    .frame(width: 24)
                
                Group {
                    if isVisible.wrappedValue {
                        TextField("", text: text)
                    } else {
                        SecureField("", text: text)
                    }
                }
                .font(.body)
                .foregroundColor(.primary)
                
                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 16)
        }
    }
    
    // MARK: - Validation Messages
    
    private var validationMessages: some View {
        VStack(alignment: .leading, spacing: 8) {
            validationRow(
                isValid: newPassword.count >= 6,
                message: "Mínimo 6 caracteres"
            )
            
            validationRow(
                isValid: passwordsMatch && !newPassword.isEmpty,
                message: "Las contraseñas coinciden"
            )
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
    
    private func validationRow(isValid: Bool, message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .secondary.opacity(0.5))
            
            Text(message)
                .font(.caption)
                .foregroundColor(isValid ? .primary : .secondary)
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            savePassword()
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Actualizar Contraseña")
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(isFormValid ? BiciTaxiTheme.accentPrimary : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!isFormValid || isSaving)
        .padding(.top, 8)
    }
    
    // MARK: - Actions
    
    private func savePassword() {
        errorMessage = nil
        isSaving = true
        
        // TODO: Implement actual password change with backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSaving = false
            showSuccessAlert = true
            print("Password changed successfully")
        }
    }
}

#Preview {
    ChangePasswordSheet()
        .preferredColorScheme(.light)
}
