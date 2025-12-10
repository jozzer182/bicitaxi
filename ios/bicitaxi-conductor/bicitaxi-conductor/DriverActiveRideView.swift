//
//  DriverActiveRideView.swift
//  bicitaxi-conductor
//
//  Active ride view for driver showing current ride and controls
//

import SwiftUI

struct DriverActiveRideView: View {
    @ObservedObject var rideViewModel: DriverRideViewModel
    var onComplete: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let ride = rideViewModel.activeRide {
                    activeRideContent(ride)
                } else {
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
            statusCard(ride)
            routeCard(ride)
            fareCard(ride)
            actionButtons(ride)
        }
    }
    
    // MARK: - Status Card
    
    private func statusCard(_ ride: Ride) -> some View {
        VStack(spacing: 16) {
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
                .foregroundColor(.white)
            
            Text("ID Cliente: \(ride.clientId)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Circle()
                    .fill(.green)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recogida")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(ride.pickup.shortDescription)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            if let dropoff = ride.dropoff {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2, height: 20)
                    .padding(.leading, 5)
                
                HStack(spacing: 12) {
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Destino")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(dropoff.shortDescription)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }
    
    // MARK: - Fare Card
    
    private func fareCard(_ ride: Ride) -> some View {
        HStack {
            Text("Tarifa")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(String(format: "$%.2f", ride.estimatedFare))
                .font(.title.weight(.bold))
                .foregroundStyle(BiciTaxiTheme.accentGradient)
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }
    
    // MARK: - Action Buttons
    
    private func actionButtons(_ ride: Ride) -> some View {
        VStack(spacing: 12) {
            switch ride.status {
            case .driverAssigned:
                Button {
                    Task { await rideViewModel.markArriving() }
                } label: {
                    Label("Ir al Punto de Recogida", systemImage: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(BiciTaxiTheme.accentGradient)
                        .clipShape(Capsule())
                }
                
            case .driverArriving:
                Button {
                    Task { await rideViewModel.startRide() }
                } label: {
                    Label("Iniciar Viaje", systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(BiciTaxiTheme.accentGradient)
                        .clipShape(Capsule())
                }
                
            case .inProgress:
                Button {
                    Task {
                        await rideViewModel.finishRide()
                        onComplete()
                    }
                } label: {
                    Label("Finalizar Viaje", systemImage: "flag.checkered")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .clipShape(Capsule())
                }
                
            default:
                EmptyView()
            }
            
            // Cancel button
            if ride.status.isActive {
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
                .foregroundColor(.white)
            
            Text("Ve a Inicio para aceptar una solicitud de viaje")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
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
        DriverActiveRideView(
            rideViewModel: DriverRideViewModel(repo: InMemoryRideRepository()),
            onComplete: {}
        )
    }
    .preferredColorScheme(.dark)
}
