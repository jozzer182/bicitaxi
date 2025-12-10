//
//  ProfileView.swift
//  bicitaxi
//
//  Profile and ride history view
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var rideViewModel: ClientRideViewModel
    
    // MARK: - Account Action States
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountSheet = false
    @State private var deleteCountdown = 10
    @State private var isDeleteButtonEnabled = false
    @State private var countdownTimer: Timer?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile header
                profileHeader
                
                // Stats
                statsCard
                
                // Ride history
                historySection
                
                // Account actions section
                accountActionsSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
        }
        .scrollContentBackground(.hidden)
        .background(.clear)
        .task {
            await rideViewModel.loadHistory()
        }
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
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(BiciTaxiTheme.accentGradient)
            
            Text("Cliente Demo")
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
            
            Text("cliente-demo")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 24)
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        HStack(spacing: 20) {
            statItem(
                value: "\(rideViewModel.history.count)",
                label: "Total Viajes"
            )
            
            Divider()
                .frame(height: 40)
                .background(Color.secondary.opacity(0.3))
            
            statItem(
                value: BiciTaxiTheme.formatCOP(totalSpent),
                label: "Total Gastado"
            )
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(BiciTaxiTheme.accentGradient)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var totalSpent: Int {
        rideViewModel.history.reduce(0) { $0 + $1.estimatedFare }
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historial de Viajes")
                .font(.headline)
                .foregroundColor(.primary)
            
            if rideViewModel.history.isEmpty {
                Text("Aún no hay viajes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(rideViewModel.history) { ride in
                    historyRow(ride)
                }
            }
        }
    }
    
    private func historyRow(_ ride: Ride) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: ride.status.iconName)
                        .foregroundColor(ride.status == .completed ? .green : .orange)
                        .font(.caption)
                    
                    Text(ride.status.displayText)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                }
                
                Text(ride.pickup.shortDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(ride.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            Spacer()
            
            Text(BiciTaxiTheme.formatCOP(ride.estimatedFare))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(16)
        .glassCard(cornerRadius: 12)
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
                    // Countdown timer
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
                
                // Delete button (disabled until countdown finishes)
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
    .preferredColorScheme(.dark)
}
