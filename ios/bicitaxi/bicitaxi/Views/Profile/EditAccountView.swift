//
//  EditAccountView.swift
//  bicitaxi
//
//  Edit account screen with name editing and password change
//

import SwiftUI

struct EditAccountView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var authManager: AuthManager
    
    // MARK: - MockData Manager
    @StateObject private var mockDataManager = MockDataManager.shared
    
    // MARK: - State
    @State private var userName: String = ""
    @State private var userEmail: String = ""
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
                    .environmentObject(authManager)
            }
            .alert("Cambios Guardados", isPresented: $showSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Tu información ha sido actualizada correctamente.")
            }
            .onAppear {
                if mockDataManager.isMockDataEnabled {
                    userName = mockDataManager.userName
                    userEmail = mockDataManager.userEmail
                } else if case .authenticated(let user) = authManager.authState {
                    userName = user.name
                    userEmail = user.email
                }
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
        if mockDataManager.isMockDataEnabled {
            // Mock Data Flow
            isSaving = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isSaving = false
                showSaveConfirmation = true
                print("User name updated to: \(userName)")
            }
        } else {
            // Real Firebase Flow
            authManager.updateProfile(name: userName) { result in
                switch result {
                case .success:
                    self.showSaveConfirmation = true
                case .failure(let error):
                    // Show error alert? ideally yes, but for now just print or no-op
                    print("Error updating profile: \(error)")
                }
            }
        }
    }
}

#Preview {
    EditAccountView()
        .environmentObject(AuthManager())
        .preferredColorScheme(.light)
}
