//
//  DriverHomeView.swift
//  bicitaxi-conductor
//
//  Driver home view with map and pending ride requests
//

import SwiftUI
import MapKit

struct DriverHomeView: View {
    @ObservedObject var rideViewModel: DriverRideViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasInitialized = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Map
                mapView
                
                // Welcome greeting overlay at top
                VStack {
                    welcomeGreeting
                        .padding(.top, geometry.safeAreaInsets.top + 60)
                    Spacer()
                }
                
                // Overlay panel at bottom
                VStack {
                    Spacer()
                    overlayPanel(geometry: geometry)
                }
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .onReceive(locationManager.$currentCoordinate) { newCoordinate in
            if let coordinate = newCoordinate {
                cameraPosition = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                ))
                
                // Initialize pending rides around driver location
                if !hasInitialized {
                    hasInitialized = true
                    Task {
                        let centerPoint = RideLocationPoint(coordinate: coordinate)
                        await rideViewModel.initializeWithDummyRides(around: centerPoint)
                    }
                }
            }
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Driver location
            UserAnnotation()
            
            // Pending ride requests
            ForEach(rideViewModel.pendingRides) { ride in
                Annotation(ride.pickup.shortDescription, coordinate: ride.pickup.coordinate) {
                    PendingRideAnnotationView(ride: ride)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, showsTraffic: true))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Welcome Greeting
    
    private var welcomeGreeting: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.wave.fill")
                .font(.title2)
                .foregroundStyle(BiciTaxiTheme.accentGradient)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("¡Bienvenido, Conductor!")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.primary)
                
                Text("Listo para aceptar viajes")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Overlay Panel
    
    private func overlayPanel(geometry: GeometryProxy) -> some View {
        let isCompact = horizontalSizeClass == .compact
        let panelWidth = isCompact ? geometry.size.width - 32 : min(geometry.size.width * 0.6, 400)
        
        return VStack(spacing: 16) {
            // Status toggle
            statusToggle
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Pending requests info
            if rideViewModel.isOnline {
                pendingRequestsView
            } else {
                offlineView
            }
        }
        .padding(20)
        .frame(width: panelWidth)
        .glassCard(cornerRadius: 24)
        .padding(.horizontal, isCompact ? 16 : 0)
        .padding(.bottom, 120)
    }
    
    // MARK: - Status Toggle
    
    private var statusToggle: some View {
        HStack {
            Text("Estado del Conductor")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button {
                rideViewModel.toggleOnline()
                if rideViewModel.isOnline {
                    Task { await rideViewModel.loadPendingRides() }
                }
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(rideViewModel.isOnline ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                    
                    Text(rideViewModel.isOnline ? "En Línea" : "Desconectado")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(rideViewModel.isOnline ? .green : .gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Pending Requests
    
    private var pendingRequestsView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bicycle")
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
                
                Text("Solicitudes Cercanas: \(rideViewModel.pendingRides.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if !rideViewModel.pendingRides.isEmpty {
                // Show first pending ride
                if let firstRide = rideViewModel.pendingRides.first {
                    pendingRideCard(firstRide)
                }
            } else {
                Text("No hay solicitudes pendientes cerca")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func pendingRideCard(_ ride: Ride) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recogida")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(ride.pickup.shortDescription)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(String(format: "$%.2f", ride.estimatedFare))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
            }
            
            Button {
                Task {
                    await rideViewModel.acceptRide(ride)
                }
            } label: {
                Text("Aceptar Viaje")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(BiciTaxiTheme.accentGradient)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Offline View
    
    private var offlineView: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.fill")
                .foregroundColor(.secondary)
            Text("Estás desconectado. Conéctate para recibir solicitudes de viaje.")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Pending Ride Annotation

struct PendingRideAnnotationView: View {
    let ride: Ride
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange)
                .frame(width: 36, height: 36)
                .shadow(color: Color.orange.opacity(0.5), radius: 8)
            
            Image(systemName: "figure.wave")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .bold))
        }
    }
}

#Preview {
    ZStack {
        BiciTaxiTheme.background.ignoresSafeArea()
        DriverHomeView(rideViewModel: DriverRideViewModel(repo: InMemoryRideRepository()))
    }
    .preferredColorScheme(.dark)
}
