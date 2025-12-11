//
//  ActiveRideView.swift
//  bicitaxi
//
//  Active ride view showing current ride status and controls
//

import SwiftUI

struct ActiveRideView: View {
    @ObservedObject var rideViewModel: ClientRideViewModel
    var onComplete: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let ride = rideViewModel.activeRide {
                    // Active ride content
                    activeRideContent(ride)
                } else {
                    // No active ride
                    noActiveRideContent
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
        }
        .scrollContentBackground(.hidden)
        .background(.clear)
    }
    
    // MARK: - Active Ride Content
    
    private func activeRideContent(_ ride: Ride) -> some View {
        VStack(spacing: 24) {
            // Status card
            statusCard(ride)
            
            // Route info
            routeCard(ride)
            
            // Action buttons
            actionButtons(ride)
        }
    }
    
    // MARK: - Status Card
    
    private func statusCard(_ ride: Ride) -> some View {
        VStack(spacing: 16) {
            // Animated status icon
            ZStack {
                Circle()
                    .fill(BiciTaxiTheme.accentPrimary.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: ride.status.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
            }
            
            Text(ride.status.displayText)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
            
            // Estimated fare
            Text("Tarifa estimada: \(BiciTaxiTheme.formatCOP(ride.estimatedFare))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 24)
    }
    
    // MARK: - Route Card
    
    private func routeCard(_ ride: Ride) -> some View {
        VStack(spacing: 16) {
            Text("Ruta")
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Pickup
            HStack(spacing: 12) {
                Circle()
                    .fill(BiciTaxiTheme.pickupColor)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recogida")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(ride.pickup.shortDescription)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            // Connector line
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 2, height: 20)
                .padding(.leading, 5)
            
            // Dropoff
            if let dropoff = ride.dropoff {
                HStack(spacing: 12) {
                    Circle()
                        .fill(BiciTaxiTheme.destinationColor)
                        .frame(width: 12, height: 12)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Destino")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(dropoff.shortDescription)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }
    
    // MARK: - Action Buttons
    
    private func actionButtons(_ ride: Ride) -> some View {
        VStack(spacing: 12) {
            // Simulate progress button (demo)
            if ride.status.isActive {
                Button {
                    Task {
                        await rideViewModel.simulateNextStatus()
                    }
                } label: {
                    Label("Simular Progreso", systemImage: "forward.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(BiciTaxiTheme.accentGradient)
                        .clipShape(Capsule())
                }
                
                // Cancel button
                Button {
                    Task {
                        await rideViewModel.cancelActiveRide()
                        onComplete()
                    }
                } label: {
                    Text("Cancelar Viaje")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - No Active Ride
    
    private var noActiveRideContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "bicycle")
                .font(.system(size: 60))
                .foregroundStyle(BiciTaxiTheme.accentGradient)
            
            Text("Sin Viaje Activo")
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
            
            Text("Ve a la pestaña de Mapa para solicitar un viaje")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 24)
    }
}

#Preview {
    ZStack {
        BiciTaxiTheme.background.ignoresSafeArea()
        ActiveRideView(
            rideViewModel: ClientRideViewModel(repo: InMemoryRideRepository()),
            onComplete: {}
        )
    }
    .preferredColorScheme(.light)
}
