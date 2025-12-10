//
//  ClientMapView.swift
//  bicitaxi
//
//  Map view for client to select pickup and dropoff locations
//

import SwiftUI
import MapKit

/// Client map view with pickup/dropoff selection
struct ClientMapView: View {
    @ObservedObject var rideViewModel: ClientRideViewModel
    @StateObject private var locationManager = LocationManager()
    
    /// Whether to show overlays (welcome, instructions, etc.)
    var showOverlays: Bool = true
    
    /// Selected pickup coordinate
    @State private var pickupLocation: CLLocationCoordinate2D?
    
    /// Selected dropoff coordinate
    @State private var dropoffLocation: CLLocationCoordinate2D?
    
    /// Reverse geocoded addresses (free via Apple's CLGeocoder)
    @State private var pickupAddress: String?
    @State private var dropoffAddress: String?
    
    /// Geocoder for reverse geocoding (free, built into iOS)
    private let geocoder = CLGeocoder()
    
    /// Map camera position
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    /// Show confirmation alert
    @State private var showConfirmAlert = false
    
    /// Flag to track if we've already set the initial pickup location
    @State private var hasSetInitialPickup = false
    
    /// Calculated route between pickup and dropoff
    @State private var calculatedRoute: MKRoute?
    
    /// Whether to use straight line fallback (when MKDirections fails)
    @State private var useStraightLineFallback = false
    
    /// Whether the welcome greeting is collapsed to a button
    @State private var isWelcomeCollapsed = false
    
    /// Route breathing animation phase (0-1)
    @State private var routeBreathingPhase: CGFloat = 0
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Map
                mapView
                
                if showOverlays {
                    // Welcome greeting overlay at top
                    VStack {
                        welcomeGreeting
                            // .padding(.top, geometry.safeAreaInsets.top + 8)
                        Spacer()
                    }
                    
                    // Liquid Glass overlay panel at bottom
                    VStack {
                        Spacer()
                        overlayPanel(geometry: geometry)
                    }
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
            
            // Start breathing animation for route line
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                routeBreathingPhase = 1.0
            }
        }
        .onReceive(locationManager.$currentCoordinate) { newCoordinate in
            if let coordinate = newCoordinate {
                // Center the map on user's current location
                cameraPosition = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
                
                // Automatically set current location as pickup on first load
                if !hasSetInitialPickup {
                    hasSetInitialPickup = true
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        pickupLocation = coordinate
                    }
                    reverseGeocode(coordinate, isPickup: true)
                }
            }
        }
        .alert("Confirmar Viaje", isPresented: $showConfirmAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Solicitar Viaje") {
                requestRide()
            }
        } message: {
            Text("¿Solicitar un viaje desde tu ubicación de recogida hasta el destino seleccionado?")
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        MapReader { reader in
            Map(position: $cameraPosition) {
                // User location
                UserAnnotation()
                
                // Route polyline (from MKDirections - FREE!)
                if let route = calculatedRoute {
                    // Breathing effect: opacity pulses from 30% to 100%
                    MapPolyline(route.polyline)
                        .stroke(
                            BiciTaxiTheme.breathingRouteGradient(phase: routeBreathingPhase),
                            lineWidth: 6
                        )
                }
                
                // Fallback: straight gradient line when MKDirections fails
                if useStraightLineFallback, 
                   let pickup = pickupLocation, 
                   let dropoff = dropoffLocation {
                    MapPolyline(coordinates: [pickup, dropoff])
                        .stroke(
                            BiciTaxiTheme.breathingRouteGradient(phase: routeBreathingPhase),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [10, 5])
                        )
                }
                
                // Pickup annotation
                if let pickup = pickupLocation {
                    Annotation("Recogida", coordinate: pickup) {
                        PickupAnnotationView()
                    }
                }
                
                // Dropoff annotation
                if let dropoff = dropoffLocation {
                    Annotation("Destino", coordinate: dropoff) {
                        DropoffAnnotationView()
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic, showsTraffic: true))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onTapGesture { location in
                if let coordinate = reader.convert(location, from: .local) {
                    handleMapTap(coordinate: coordinate)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Welcome Greeting
    
    private var welcomeGreeting: some View {
        HStack {
            Spacer()
            
            if isWelcomeCollapsed {
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
//                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
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
                        Text("Bienvenido a Bici Taxi")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.primary)
                        
                        Text("Solicita un viaje en cualquier momento")
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
    }
    
    // MARK: - Overlay Panel
    
    private func overlayPanel(geometry: GeometryProxy) -> some View {
        let isCompact = horizontalSizeClass == .compact
        let panelWidth = isCompact ? geometry.size.width - 32 : min(geometry.size.width * 0.6, 400)
        
        return VStack(spacing: 16) {
            // Status/Instructions
            statusView
            
            // Action buttons
            if pickupLocation != nil || dropoffLocation != nil {
                actionButtons
            }
        }
        .padding(20)
        .frame(width: panelWidth)
        .glassCard(cornerRadius: 24)
        .padding(.horizontal, isCompact ? 16 : 0)
        .padding(.bottom, 100)  // Reduced spacing above tab bar
    }
    
    // MARK: - Status View
    
    @ViewBuilder
    private var statusView: some View {
        if let error = locationManager.errorMessage {
            HStack(spacing: 12) {
                Image(systemName: "location.slash.fill")
                    .foregroundColor(.orange)
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.8))
            }
        } else if locationManager.isLocating {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(BiciTaxiTheme.accentPrimary)
                Text("Buscando tu ubicación...")
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.8))
            }
        } else if pickupLocation == nil {
            instructionText("Toca el mapa para elegir tu punto de recogida")
        } else if dropoffLocation == nil {
            VStack(spacing: 8) {
                locationRow(title: "Recogida", coordinate: pickupLocation, address: pickupAddress, color: BiciTaxiTheme.pickupColor)
                instructionText("Toca de nuevo para elegir tu destino")
            }
        } else {
            VStack(spacing: 8) {
                locationRow(title: "Recogida", coordinate: pickupLocation, address: pickupAddress, color: BiciTaxiTheme.pickupColor)
                
                Image(systemName: "arrow.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                locationRow(title: "Destino", coordinate: dropoffLocation, address: dropoffAddress, color: BiciTaxiTheme.destinationColor)
            }
        }
    }
    
    private func instructionText(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .foregroundStyle(BiciTaxiTheme.accentGradient)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
        }
    }
    
    private func locationRow(title: String, coordinate: CLLocationCoordinate2D?, address: String?, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                // Show address if available
                if let address = address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.8))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let coord = coordinate {
                // Convert to DMS and show only minutes and seconds
                // Minutes in softer color, seconds more prominent
                HStack(spacing: 2) {
                    // Latitude minutes'seconds"
                    let (latMin, latSec) = minutesAndSeconds(from: coord.latitude)
                    Text("\(latMin)'")
                        .foregroundColor(.secondary.opacity(0.6))
                    Text(String(format: "%.1f\"", latSec))
                        .foregroundColor(.secondary)
                    
                    Text(" ")
                    
                    // Longitude minutes'seconds"
                    let (lonMin, lonSec) = minutesAndSeconds(from: coord.longitude)
                    Text("\(lonMin)'")
                        .foregroundColor(.secondary.opacity(0.6))
                    Text(String(format: "%.1f\"", lonSec))
                        .foregroundColor(.secondary)
                }
                .font(.caption2)
            }
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
    
    /// Reverse geocode a coordinate to get the address (free via Apple's CLGeocoder)
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D, isPickup: Bool) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                return
            }
            
            // Build a short address string
            var addressParts: [String] = []
            
            if let name = placemark.name, !name.isEmpty {
                addressParts.append(name)
            } else if let street = placemark.thoroughfare {
                if let number = placemark.subThoroughfare {
                    addressParts.append("\(number) \(street)")
                } else {
                    addressParts.append(street)
                }
            }
            
            if let locality = placemark.locality {
                addressParts.append(locality)
            }
            
            let address = addressParts.joined(separator: ", ")
            
            DispatchQueue.main.async {
                if isPickup {
                    pickupAddress = address.isEmpty ? nil : address
                } else {
                    dropoffAddress = address.isEmpty ? nil : address
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                clearLocations()
            } label: {
                Text("Limpiar")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            if pickupLocation != nil && dropoffLocation != nil {
                Button {
                    showConfirmAlert = true
                } label: {
                    Text("Confirmar Ubicaciones")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(BiciTaxiTheme.accentGradient)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleMapTap(coordinate: CLLocationCoordinate2D) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if pickupLocation == nil {
                pickupLocation = coordinate
                reverseGeocode(coordinate, isPickup: true)
            } else if dropoffLocation == nil {
                dropoffLocation = coordinate
                reverseGeocode(coordinate, isPickup: false)
                // Calculate route now that we have both points
                calculateRoute()
            } else {
                // Replacing dropoff
                dropoffLocation = coordinate
                reverseGeocode(coordinate, isPickup: false)
                // Recalculate route with new dropoff
                calculateRoute()
            }
        }
    }
    
    private func clearLocations() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            pickupLocation = nil
            dropoffLocation = nil
            pickupAddress = nil
            dropoffAddress = nil
            calculatedRoute = nil
            useStraightLineFallback = false
        }
    }
    
    /// Calculate route between pickup and dropoff using MKDirections (FREE API)
    private func calculateRoute() {
        guard let pickup = pickupLocation, let dropoff = dropoffLocation else { return }
        
        // Reset route state
        calculatedRoute = nil
        useStraightLineFallback = false
        
        // Create MKDirections request (FREE - Apple's built-in service)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickup))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dropoff))
        request.transportType = .walking  // Bike taxi is similar to walking routes
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        Task {
            do {
                let response = try await directions.calculate()
                
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if let route = response.routes.first {
                            calculatedRoute = route
                            useStraightLineFallback = false
                            
                            // Adjust camera to show full route with more padding
                            let routeRect = route.polyline.boundingMapRect
                            let paddedRect = routeRect.insetBy(dx: -routeRect.size.width * 0.5, dy: -routeRect.size.height * 0.5)
                            cameraPosition = .rect(paddedRect)
                        }
                    }
                }
            } catch {
                // Fallback to straight line if MKDirections fails
                print("MKDirections failed: \(error.localizedDescription). Using straight line fallback.")
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        useStraightLineFallback = true
                    }
                }
            }
        }
    }
    
    private func requestRide() {
        guard let pickup = pickupLocation else { return }
        
        let pickupPoint = RideLocationPoint(coordinate: pickup)
        let dropoffPoint = dropoffLocation.map { RideLocationPoint(coordinate: $0) }
        
        Task {
            await rideViewModel.requestRide(pickup: pickupPoint, dropoff: dropoffPoint)
            
            // Clear selections after request
            await MainActor.run {
                pickupLocation = nil
                dropoffLocation = nil
            }
        }
    }
}

// MARK: - Annotation Views

struct PickupAnnotationView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(BiciTaxiTheme.pickupColor)
                .frame(width: 32, height: 32)
                .shadow(color: BiciTaxiTheme.pickupColor.opacity(0.5), radius: 8)
            
            Image(systemName: "figure.wave")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .bold))
        }
    }
}

struct DropoffAnnotationView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(BiciTaxiTheme.destinationColor)
                .frame(width: 32, height: 32)
                .shadow(color: BiciTaxiTheme.destinationColor.opacity(0.5), radius: 8)
            
            Image(systemName: "flag.fill")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .bold))
        }
    }
}

#Preview {
    ZStack {
        BiciTaxiTheme.background.ignoresSafeArea()
        ClientMapView(rideViewModel: ClientRideViewModel(repo: InMemoryRideRepository()))
    }
    .preferredColorScheme(.dark)
}
