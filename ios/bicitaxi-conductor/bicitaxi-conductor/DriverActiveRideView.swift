//
//  DriverActiveRideView.swift
//  bicitaxi-conductor
//
//  Active ride view for driver showing current ride and controls
//

import SwiftUI
import CoreLocation

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
                .foregroundColor(.primary)
            
            Text("ID Cliente: \(ride.clientId)")
                .font(.caption)
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
            
            // Pickup location row
            locationRow(
                title: "Recogida",
                address: ride.pickup.shortDescription,
                coordinate: ride.pickup.coordinate,
                color: BiciTaxiTheme.pickupColor
            )
            
            // Connector line
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 2, height: 20)
                .padding(.leading, 5)
            
            // Dropoff location row
            if let dropoff = ride.dropoff {
                locationRow(
                    title: "Destino",
                    address: dropoff.shortDescription,
                    coordinate: dropoff.coordinate,
                    color: BiciTaxiTheme.destinationColor
                )
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }
    
    /// Location row matching ClientMapView format with coordinate display
    private func locationRow(title: String, address: String, coordinate: CLLocationCoordinate2D, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(address)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Coordinate display with gradient (matching client app)
            HStack(spacing: 2) {
                let (latMin, latSec) = minutesAndSeconds(from: coordinate.latitude)
                Text("\(latMin)'")
                    .foregroundColor(.secondary.opacity(0.6))
                Text(String(format: "%.1f\"", latSec))
                    .foregroundColor(.secondary)
                
                Text(" ")
                
                let (lonMin, lonSec) = minutesAndSeconds(from: coordinate.longitude)
                Text("\(lonMin)'")
                    .foregroundColor(.secondary.opacity(0.6))
                Text(String(format: "%.1f\"", lonSec))
                    .foregroundColor(.secondary)
            }
            .font(.caption2)
        }
    }
    
    /// Extract minutes and seconds from a decimal degree coordinate
    private func minutesAndSeconds(from decimalDegrees: Double) -> (Int, Double) {
        let absolute = abs(decimalDegrees)
        let degrees = Int(absolute)
        let minutesDecimal = (absolute - Double(degrees)) * 60
        let minutes = Int(minutesDecimal)
        let seconds = (minutesDecimal - Double(minutes)) * 60
        return (minutes, seconds)
    }
    
    // MARK: - Fare Card
    
    private func fareCard(_ ride: Ride) -> some View {
        HStack {
            Text("Tarifa")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(BiciTaxiTheme.formatCOP(ride.estimatedFare))
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
                .foregroundColor(.primary)
            
            Text("Ve a Inicio para aceptar una solicitud de viaje")
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
        DriverActiveRideView(
            rideViewModel: DriverRideViewModel(repo: InMemoryRideRepository()),
            onComplete: {}
        )
    }
    .preferredColorScheme(.dark)
}
