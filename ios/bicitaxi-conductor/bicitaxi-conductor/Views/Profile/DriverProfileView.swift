//
//  DriverProfileView.swift
//  bicitaxi-conductor
//
//  Simplified driver profile view with settings
//

import SwiftUI

struct DriverProfileView: View {
    @ObservedObject var rideViewModel: DriverRideViewModel
    @EnvironmentObject var authManager: AuthManager
    
    // MARK: - MockData Manager
    @StateObject private var mockDataManager = MockDataManager.shared
    
    // MARK: - State
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountSheet = false
    @State private var deleteCountdown = 10
    @State private var isDeleteButtonEnabled = false
    @State private var countdownTimer: Timer?
    @State private var showPaymentMethods = false
    @State private var showAbout = false
    @State private var showEditAccount = false
    @State private var showMockDataWarning = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Name header with status (no photo)
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
        .alert("⚠️ Datos de Prueba", isPresented: $showMockDataWarning) {
            Button("Cancelar", role: .cancel) {
                // Keep mock data disabled
            }
            Button("Continuar") {
                mockDataManager.isMockDataEnabled = true
            }
        } message: {
            Text("Los datos que verás son FALSOS y solo para pruebas. No se conectará a la base de datos real.\n\n¿Deseas continuar?")
        }
    }
    
    // MARK: - Helpers
    
    private var displayedName: String {
        if mockDataManager.isMockDataEnabled {
            return mockDataManager.userName
        }
        
        switch authManager.authState {
        case .authenticated(let driver):
            return driver.name
        case .guest:
            return "Invitado"
        default:
            return "Sin Usuario"
        }
    }
    
    // MARK: - Name Header
    
    private var nameHeader: some View {
        Button {
            showEditAccount = true
        } label: {
            VStack(spacing: 16) {
                Text(displayedName)
                    .font(.title.weight(.bold))
                    .foregroundColor(.primary)
                
                // Online status badge
                HStack(spacing: 8) {
                    Circle()
                        .fill(rideViewModel.isOnline ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(rideViewModel.isOnline ? "En Línea" : "Desconectado")
                        .font(.caption)
                        .foregroundColor(rideViewModel.isOnline ? .green : .gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
                
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
            // Mockup data toggle
            HStack {
                Image(systemName: "flask.fill")
                    .foregroundColor(BiciTaxiTheme.accentPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Datos de Demostración")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("Desactiva para preparar Firebase")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { mockDataManager.isMockDataEnabled },
                    set: { newValue in
                        if newValue {
                            // Show warning when trying to enable
                            showMockDataWarning = true
                        } else {
                            // Allow disabling without warning
                            mockDataManager.isMockDataEnabled = false
                        }
                    }
                ))
                    .labelsHidden()
                    .tint(BiciTaxiTheme.accentPrimary)
            }
            .padding(16)
            .glassCard(cornerRadius: 12)
            
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
                
                Text("Se eliminarán permanentemente todos tus datos, historial de viajes, ganancias y configuración. No podrás recuperar esta cuenta de conductor.")
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
        authManager.signOut()
    }
    
    private func handleDeleteAccount() {
        // TODO: Implement actual account deletion logic
        print("Driver account deletion requested")
        showDeleteAccountSheet = false
    }
}

#Preview {
    ZStack {
        BiciTaxiTheme.background.ignoresSafeArea()
        DriverProfileView(rideViewModel: DriverRideViewModel(repo: InMemoryRideRepository()))
            .environmentObject(AuthManager())
    }
    .preferredColorScheme(.light)
}
