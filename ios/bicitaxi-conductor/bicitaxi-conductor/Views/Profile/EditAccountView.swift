//
//  EditAccountView.swift
//  bicitaxi-conductor
//
//  Edit account screen with name editing and password change
//

import SwiftUI

struct EditAccountView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var userName: String = "Conductor Demo"
    @State private var userEmail: String = "conductor@demo.com"
    @State private var showChangePassword = false
    @State private var showSaveConfirmation = false
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Name field
                    nameSection
                    
                    // Email field (read-only)
                    emailSection
                    
                    // Change password button
                    changePasswordButton
                    
                    // Save button
                    saveButton
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
            .scrollContentBackground(.hidden)
            .background(BiciTaxiTheme.background.ignoresSafeArea())
            .navigationTitle("Editar Cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(BiciTaxiTheme.accentPrimary)
                }
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordSheet()
            }
            .alert("Cambios Guardados", isPresented: $showSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Tu información ha sido actualizada correctamente.")
            }
        }
    }
    
    // MARK: - Name Section
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nombre")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .foregroundColor(BiciTaxiTheme.accentPrimary)
                    .frame(width: 24)
                
                TextField("Tu nombre", text: $userName)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .padding(16)
            .glassCard(cornerRadius: 16)
        }
    }
    
    // MARK: - Email Section (Read-only)
    
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Correo electrónico")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                    Text("No editable")
                        .font(.caption2)
                }
                .foregroundColor(.secondary.opacity(0.7))
            }
            
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                Text(userEmail)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(16)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Change Password Button
    
    private var changePasswordButton: some View {
        Button {
            showChangePassword = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .foregroundColor(BiciTaxiTheme.accentPrimary)
                    .frame(width: 24)
                
                Text("Cambiar Contraseña")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(16)
            .glassCard(cornerRadius: 16)
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            saveChanges()
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Guardar Cambios")
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(BiciTaxiTheme.accentPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isSaving)
        .padding(.top, 8)
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        isSaving = true
        
        // TODO: Implement actual save logic with backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            showSaveConfirmation = true
            print("Driver name updated to: \(userName)")
        }
    }
}

#Preview {
    EditAccountView()
        .preferredColorScheme(.light)
}
