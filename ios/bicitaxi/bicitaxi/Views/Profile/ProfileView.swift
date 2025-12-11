//
//  ProfileView.swift
//  bicitaxi
//
//  Simplified profile view with settings
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var rideViewModel: ClientRideViewModel
    
    // MARK: - State
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountSheet = false
    @State private var deleteCountdown = 10
    @State private var isDeleteButtonEnabled = false
    @State private var countdownTimer: Timer?
    @State private var showPaymentMethods = false
    @State private var showAbout = false
    @State private var showEditAccount = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Name header (no photo)
                nameHeader
                
                // Settings section (Pagos, Acerca de)
                settingsSection
                
                // Account actions
                accountActionsSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
        }
        .scrollContentBackground(.hidden)
        .background(.clear)
        .alert("Cerrar Sesión", isPresented: $showLogoutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar Sesión", role: .destructive) {
                handleLogout()
            }
        } message: {
            Text("¿Estás seguro de que deseas cerrar sesión?")
        }
        .sheet(isPresented: $showDeleteAccountSheet, onDismiss: resetDeleteState) {
            deleteAccountSheet
        }
        .sheet(isPresented: $showPaymentMethods) {
            PaymentMethodsView()
        }
        .sheet(isPresented: $showAbout) {
            AboutSheet()
        }
        .sheet(isPresented: $showEditAccount) {
            EditAccountView()
        }
    }
    
    // MARK: - Name Header
    
    private var nameHeader: some View {
        Button {
            showEditAccount = true
        } label: {
            VStack(spacing: 12) {
                Text("Cliente Demo")
                    .font(.title.weight(.bold))
                    .foregroundColor(.primary)
                
                Text("cliente-demo")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Edit hint
                HStack(spacing: 4) {
                    Image(systemName: "pencil")
                        .font(.caption2)
                    Text("Toca para editar")
                        .font(.caption2)
                }
                .foregroundColor(BiciTaxiTheme.accentPrimary)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: 24)
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuración")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Payment Methods
            Button {
                showPaymentMethods = true
            } label: {
                settingsRow(icon: "creditcard.fill", title: "Métodos de Pago")
            }
            
            // About
            Button {
                showAbout = true
            } label: {
                settingsRow(icon: "info.circle.fill", title: "Acerca de")
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }
    
    private func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Account Actions Section
    
    private var accountActionsSection: some View {
        VStack(spacing: 12) {
            // Logout button
            Button {
                showLogoutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.orange)
                    Text("Cerrar Sesión")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .glassCard(cornerRadius: 12)
            }
            
            // Delete account button
            Button {
                showDeleteAccountSheet = true
                startDeleteCountdown()
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    Text("Eliminar Cuenta")
                        .foregroundColor(.red)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .glassCard(cornerRadius: 12)
            }
        }
    }
    
    // MARK: - Delete Account Sheet
    
    private var deleteAccountSheet: some View {
        VStack(spacing: 24) {
            // Warning icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
            }
            .padding(.top, 32)
            
            // Warning title
            Text("⚠️ Eliminar Cuenta")
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
            
            // Warning message
            VStack(spacing: 12) {
                Text("Esta acción es irreversible")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text("Se eliminarán permanentemente todos tus datos, historial de viajes y configuración. No podrás recuperar esta cuenta.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Countdown or delete button
            VStack(spacing: 16) {
                if !isDeleteButtonEnabled {
                    Text("El botón se habilitará en")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(deleteCountdown)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                    
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(deleteCountdown) / 10.0)
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: deleteCountdown)
                    }
                }
                
                // Delete button
                Button {
                    handleDeleteAccount()
                } label: {
                    Text(isDeleteButtonEnabled ? "Eliminar Cuenta Permanentemente" : "Esperando...")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isDeleteButtonEnabled ? Color.red : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isDeleteButtonEnabled)
                
                // Cancel button
                Button {
                    showDeleteAccountSheet = false
                } label: {
                    Text("Cancelar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Account Actions
    
    private func startDeleteCountdown() {
        deleteCountdown = 10
        isDeleteButtonEnabled = false
        
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if deleteCountdown > 1 {
                deleteCountdown -= 1
            } else {
                timer.invalidate()
                isDeleteButtonEnabled = true
            }
        }
    }
    
    private func resetDeleteState() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        deleteCountdown = 10
        isDeleteButtonEnabled = false
    }
    
    private func handleLogout() {
        // TODO: Implement actual logout logic
        print("User logged out")
    }
    
    private func handleDeleteAccount() {
        // TODO: Implement actual account deletion logic
        print("Account deletion requested")
        showDeleteAccountSheet = false
    }
}

#Preview {
    ZStack {
        BiciTaxiTheme.background.ignoresSafeArea()
        ProfileView(rideViewModel: ClientRideViewModel(repo: InMemoryRideRepository()))
    }
    .preferredColorScheme(.light)
}
