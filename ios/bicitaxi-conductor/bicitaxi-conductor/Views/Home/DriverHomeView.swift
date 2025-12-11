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
    @StateObject private var mockDataManager = MockDataManager.shared
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasInitialized = false
    
    /// Whether the welcome greeting is collapsed to a button
    @State private var isWelcomeCollapsed = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Map
                mapView
                
                // Welcome greeting overlay at top
                VStack {
                    welcomeGreeting
                        //.padding(.top, geometry.safeAreaInsets.top)
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
            
            // Auto-collapse welcome greeting after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isWelcomeCollapsed = true
                }
            }
        }
        .onReceive(locationManager.$currentCoordinate) { newCoordinate in
            if let coordinate = newCoordinate {
                cameraPosition = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                ))
                
                // Initialize pending rides around driver location (only with mock data enabled)
                if !hasInitialized {
                    hasInitialized = true
                    if mockDataManager.isMockDataEnabled {
                        Task {
                            let centerPoint = RideLocationPoint(coordinate: coordinate)
                            await rideViewModel.initializeWithDummyRides(around: centerPoint)
                        }
                    }
                }
            }
        }
        .onChange(of: mockDataManager.isMockDataEnabled) { _, isEnabled in
            if !isEnabled {
                // Clear dummy data when mock data is disabled
                rideViewModel.clearPendingRides()
            } else {
                // Regenerate dummy data when mock data is re-enabled
                if let coordinate = locationManager.currentCoordinate {
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
            // Hide default controls - custom ones below greeting button
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Welcome Greeting
    
    private var welcomeGreeting: some View {
        VStack(spacing: 0) {
            // Greeting message (expanded or collapsed)
            HStack {
                if isWelcomeCollapsed {
                    Spacer()
                    // Collapsed: Circular Liquid Glass button with white hand wave icon
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            isWelcomeCollapsed = false
                        }
                        // Re-collapse after 5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isWelcomeCollapsed = true
                            }
                        }
                    } label: {
                        Image(systemName: "hand.wave.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                            .frame(width: 50, height: 50)
                    }
                    .glassEffect(.clear.interactive())
                    .clipShape(Circle())
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                    .padding(.trailing, 16)
                } else {
                    // Expanded: Full welcome message
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
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .onTapGesture {
                        // Allow tapping to manually collapse
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isWelcomeCollapsed = true
                        }
                    }
                }
            }
            
            // Custom map controls - always aligned to the right
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    // User location button
                    Button {
                        if let coordinate = locationManager.currentCoordinate {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                                ))
                            }
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                    }
                    .glassEffect(.clear.interactive())
                    .clipShape(Circle())
                    
                    // Compass button (reset view)
                    Button {
                        // Reset camera to a slightly zoomed out view
                        if let coordinate = locationManager.currentCoordinate {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                                ))
                            }
                        }
                    } label: {
                        Image(systemName: "safari")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                    }
                    .glassEffect(.clear.interactive())
                    .clipShape(Circle())
                }
                .padding(.trailing, 16)
                .padding(.top, 12)
            }
        }
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
                // Compact scrollable list of all pending requests
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(rideViewModel.pendingRides) { ride in
                            compactRideRequest(ride)
                        }
                    }
                }
                .frame(maxHeight: 200) // Limit height for compact view
            } else {
                Text("No hay solicitudes pendientes cerca")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    /// Compact ride request row showing: Distance, Destination, Client, Fare, Accept
    private func compactRideRequest(_ ride: Ride) -> some View {
        HStack(spacing: 10) {
            // Distance indicator
            VStack(spacing: 2) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.caption2)
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
                Text(formatDistance(ride))
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.primary)
            }
            .frame(width: 40)
            
            // Route info: pickup → destination
            VStack(alignment: .leading, spacing: 2) {
                // Client name
                Text(clientDisplayName(ride.clientId))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Destination
                if let dropoff = ride.dropoff {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(BiciTaxiTheme.destinationColor)
                            .frame(width: 6, height: 6)
                        Text(dropoff.shortDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Fare
            Text(BiciTaxiTheme.formatCOP(ride.estimatedFare))
                .font(.caption.weight(.bold))
                .foregroundStyle(BiciTaxiTheme.accentGradient)
            
            // Accept button
            Button {
                Task {
                    await rideViewModel.acceptRide(ride)
                }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 12)
    }
    
    /// Calculate and format distance in km between pickup and dropoff
    private func formatDistance(_ ride: Ride) -> String {
        guard let dropoff = ride.dropoff else { return "---" }
        
        let latDiff = abs(dropoff.latitude - ride.pickup.latitude)
        let lonDiff = abs(dropoff.longitude - ride.pickup.longitude)
        let distance = sqrt(latDiff * latDiff + lonDiff * lonDiff) * 111 // ~km
        
        if distance < 1 {
            return String(format: "%.0fm", distance * 1000)
        }
        return String(format: "%.1fkm", distance)
    }
    
    /// Get display name for client (demo names based on clientId)
    private func clientDisplayName(_ clientId: String) -> String {
        switch clientId {
        case "client-001": return "Carlos García"
        case "client-002": return "María López"
        case "client-003": return "Juan Martínez"
        case "client-004": return "Ana Rodríguez"
        default: return "Cliente \(clientId.suffix(3))"
        }
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
    .preferredColorScheme(.light)
}
