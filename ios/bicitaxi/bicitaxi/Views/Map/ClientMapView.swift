//
//  ClientMapView.swift
//  bicitaxi
//
//  Map view for client to select pickup and dropoff locations
//

import SwiftUI
import MapKit
import Combine

/// Tracking state for the map screen
enum TrackingState {
    case selecting
    case searching
    case tracking
    case driverArrived
    case tripStarted
}

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
    
    // MARK: - Tracking State
    
    /// Current tracking state
    @State private var trackingState: TrackingState = .selecting
    
    /// Request service for Firebase requests
    private let requestService = RequestService()
    
    /// Active request being tracked
    @State private var activeRequest: RideRequest?
    
    /// Driver's current position
    @State private var driverPosition: CLLocationCoordinate2D?
    
    /// Whether driver arrived notification was shown
    @State private var arrivedNotified = false
    
    /// Heartbeat timer for active requests
    @State private var heartbeatTimer: Timer?
    
    /// Cancellable subscriptions
    @State private var cancellables = Set<AnyCancellable>()
    
    /// Show pickup confirmed alert
    @State private var showPickupConfirmedAlert = false
    
    /// Who confirmed the pickup ("pasajero" or "conductor")
    @State private var confirmedBy: String = ""
    
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
                    
                    // Driver count overlay - shows nearby drivers (positioned left, above bottom panel)
                    // Only show when we have real coordinates (not default fallback)
                    if let coord = locationManager.currentCoordinate {
                        VStack {
                            Spacer()
                            HStack {
                                DriverCountOverlay(
                                    lat: coord.latitude,
                                    lng: coord.longitude
                                )
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 340) // Match Flutter's bottom: 340 positioning
                        }
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
            observeRequestUpdates() // Start observing request updates
            
            // Auto-collapse welcome greeting after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isWelcomeCollapsed = true
                }
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
        .alert("¡Recogida Confirmada!", isPresented: $showPickupConfirmedAlert) {
            Button("¡Buen Viaje!") {
                resetTracking()
            }
        } message: {
            Text("La recogida ha sido confirmada por el \(confirmedBy).\n\n¡Que disfrutes tu viaje! Ya puedes cerrar la app.")
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
                    // Static route line with solid color for best performance
                    MapPolyline(route.polyline)
                        .stroke(
                            BiciTaxiTheme.routeColor,
                            lineWidth: 6
                        )
                }
                
                // Fallback: straight dashed line when MKDirections fails
                if useStraightLineFallback, 
                   let pickup = pickupLocation, 
                   let dropoff = dropoffLocation {
                    MapPolyline(coordinates: [pickup, dropoff])
                        .stroke(
                            BiciTaxiTheme.routeColor,
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
                
                // Driver annotation (when tracking)
                if let driver = driverPosition,
                   (trackingState == .tracking || trackingState == .driverArrived) {
                    Annotation("Conductor", coordinate: driver) {
                        DriverAnnotationView(isArrived: trackingState == .driverArrived)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic, showsTraffic: true))
            .mapControls {
                // Hide default controls - we'll add custom ones below the greeting button
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
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
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
                    
                    // Compass button (3D view toggle for fun)
                    Button {
                        // Reset camera to top-down view at current location
                        if let coordinate = locationManager.currentCoordinate {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
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
            // Status/Instructions
            statusView
            
            // Action buttons (only in selecting state)
            if trackingState == .selecting && (pickupLocation != nil || dropoffLocation != nil) {
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
        // Priority 1: Show searching/tracking states
        if trackingState == .searching {
            searchingView
        } else if trackingState == .tracking {
            trackingView
        } else if trackingState == .driverArrived {
            driverArrivedView
        } else if trackingState == .tripStarted {
            tripStartedView
        }
        // Priority 2: Show location/error states when selecting
        else if let error = locationManager.errorMessage {
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
    
    // MARK: - Searching View
    
    private var searchingView: some View {
        VStack(spacing: 16) {
            // Spinning indicator with message
            ProgressView()
                .scaleEffect(1.5)
                .tint(BiciTaxiTheme.accentPrimary)
            
            Text("Buscando conductor...")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            Text("Tu solicitud ha sido enviada")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Cancel button
            Button {
                cancelRequest()
            } label: {
                Text("Cancelar solicitud")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Tracking View
    
    private var trackingView: some View {
        VStack(spacing: 12) {
            // Header with driver info
            HStack {
                Image(systemName: "bicycle.circle.fill")
                    .font(.title)
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Show driver name if available
                    let driverName = requestService.activeRequest?.driverName ?? "Conductor"
                    Text("¡\(driverName) en camino!")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text("Espera en tu punto de recogida")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("EN VIVO")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
                .clipShape(Capsule())
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Action buttons
            HStack(spacing: 12) {
                // Cancel button
                Button {
                    cancelRequest()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancelar")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Confirm pickup button (passenger confirms they've been picked up)
                Button {
                    confirmPickup()
                } label: {
                    HStack {
                        Image(systemName: "person.fill.checkmark")
                        Text("Confirmar Recogida")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(BiciTaxiTheme.accentGradient)
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    /// Confirm that the passenger has been picked up (ends app intervention)
    private func confirmPickup() {
        guard let request = activeRequest else { return }
        
        Task {
            await requestService.completeRequest(cellId: request.cellId, requestId: request.requestId)
            await MainActor.run {
                confirmedBy = "pasajero"
                showPickupConfirmedAlert = true
            }
        }
    }
    
    // MARK: - Driver Arrived View
    
    private var driverArrivedView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "hand.wave.fill")
                    .font(.title)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("¡El conductor ha llegado!")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text("Busca tu bicitaxi")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Trip Started View
    
    private var tripStartedView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "figure.outdoor.cycle")
                    .font(.title)
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Viaje en curso")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text("Disfruta tu viaje")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Cancel Request
    
    private func cancelRequest() {
        guard let request = activeRequest else {
            resetTracking()
            return
        }
        
        Task {
            await requestService.cancelRequest(cellId: request.cellId, requestId: request.requestId)
            await MainActor.run {
                resetTracking()
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
    /// Reverse geocode a coordinate to get the address (modern async/await)
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D, isPickup: Bool) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                guard let placemark = placemarks.first else { return }
                
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
                
                await MainActor.run {
                    if isPickup {
                        pickupAddress = address.isEmpty ? nil : address
                    } else {
                        dropoffAddress = address.isEmpty ? nil : address
                    }
                }
            } catch {
                print("Reverse geocoding failed: \(error.localizedDescription)")
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
        // Only allow selection in selecting state
        guard trackingState == .selecting else { return }
        
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
        
        // Transition to searching state
        trackingState = .searching
        
        Task {
            // Create Firebase request via RequestService
            let request = await requestService.createRequest(
                pickupLat: pickup.latitude,
                pickupLng: pickup.longitude,
                dropoffLat: dropoffLocation?.latitude,
                dropoffLng: dropoffLocation?.longitude,
                pickupAddress: pickupAddress,
                dropoffAddress: dropoffAddress
            )
            
            guard let request = request else {
                await MainActor.run {
                    trackingState = .selecting
                }
                return
            }
            
            await MainActor.run {
                activeRequest = request
                // Start watching this request for updates
                requestService.watchRequest(cellId: request.cellId, requestId: request.requestId)
                // Start heartbeat timer (every 30 seconds)
                startHeartbeat(cellId: request.cellId, requestId: request.requestId)
            }
        }
    }
    
    // MARK: - Request Update Handler
    
    /// Call this from view lifecycle to observe request changes
    private func observeRequestUpdates() {
        // Observe requestService.activeRequest for real-time updates
        requestService.$activeRequest
            .receive(on: DispatchQueue.main)
            .sink { [self] request in
                guard let request = request else { return }
                
                // Update driver position
                if let lat = request.driverLat, let lng = request.driverLng {
                    driverPosition = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    checkDriverProximity()
                }
                
                // Update tracking state
                switch request.status {
                case .open:
                    trackingState = .searching
                case .assigned:
                    trackingState = .tracking
                case .completed:
                    // If we didn't confirm ourselves, the conductor confirmed
                    if !showPickupConfirmedAlert {
                        confirmedBy = "conductor"
                        showPickupConfirmedAlert = true
                    }
                case .cancelled:
                    resetTracking()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Check if driver is within 50m of pickup
    private func checkDriverProximity() {
        guard let driver = driverPosition,
              let pickup = pickupLocation,
              !arrivedNotified,
              trackingState == .tracking else { return }
        
        let pickupLoc = CLLocation(latitude: pickup.latitude, longitude: pickup.longitude)
        let driverLoc = CLLocation(latitude: driver.latitude, longitude: driver.longitude)
        let distance = pickupLoc.distance(from: driverLoc)
        
        if distance < 50 {
            trackingState = .driverArrived
            arrivedNotified = true
            // Show notification to user
        }
    }
    
    // MARK: - Heartbeat
    
    /// Starts a periodic timer to check if conductor is still active (locally, no DB writes)
    /// Uses the snapshot listener to receive conductor updates, this just checks staleness
    private func startHeartbeat(cellId: String, requestId: String) {
        heartbeatTimer?.invalidate()
        // Check every 30 seconds if conductor is still active (locally)
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            if trackingState == .searching || trackingState == .tracking {
                checkConductorStaleness()
            } else {
                heartbeatTimer?.invalidate()
                heartbeatTimer = nil
            }
        }
    }
    
    /// Check if conductor has gone stale (no updates for 3 minutes)
    private func checkConductorStaleness() {
        guard let request = activeRequest else { return }
        
        let lastUpdate = request.updatedAt
        let now = Date()
        let staleDuration: TimeInterval = 180 // 3 minutes
        
        if now.timeIntervalSince(lastUpdate) > staleDuration {
            // Conductor has not updated in 3 minutes - likely disconnected
            print("⚠️ Conductor appears disconnected (no updates for 3+ minutes)")
            heartbeatTimer?.invalidate()
            heartbeatTimer = nil
            
            // Show notification and cancel request
            // The view will update based on trackingState change
            Task {
                await requestService.cancelRequest(cellId: request.cellId, requestId: request.requestId)
            }
            resetTracking()
        }
    }
    
    /// Reset tracking state
    private func resetTracking() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        requestService.stopWatchingRequest()
        trackingState = .selecting
        activeRequest = nil
        driverPosition = nil
        arrivedNotified = false
        cancellables.removeAll()
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

struct DriverAnnotationView: View {
    var isArrived: Bool
    
    // Use orange for driver to distinguish from blue pickup/destination
    private let driverColor: Color = .orange
    
    var body: some View {
        ZStack {
            Circle()
                .fill(driverColor)
                .frame(width: 40, height: 40)
                .shadow(color: driverColor.opacity(0.5), radius: isArrived ? 4 : 12)
                .scaleEffect(isArrived ? 1.0 : 1.1)
            
            Image(systemName: "bicycle")
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .bold))
        }
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isArrived)
    }
}

#Preview {
    ZStack {
        BiciTaxiTheme.background.ignoresSafeArea()
        ClientMapView(rideViewModel: ClientRideViewModel(repo: InMemoryRideRepository()))
    }
    .preferredColorScheme(.light)
}
