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
    @StateObject private var requestService = RequestService() // Firebase requests
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasInitialized = false
    
    /// Whether the welcome greeting is collapsed to a button
    @State private var isWelcomeCollapsed = false
    
    /// Active Firebase request (after conductor accepts)
    @State private var activeFirebaseRequest: RideRequest?
    
    /// Timer for updating driver location during active ride
    @State private var driverLocationTimer: Timer?
    
    /// Show pickup confirmed alert
    @State private var showPickupConfirmedAlert = false
    
    /// Who confirmed the pickup ("conductor" or "pasajero")
    @State private var confirmedBy: String = ""
    
    /// Whether the ride info panel is collapsed
    @State private var isRideInfoCollapsed = false
    
    /// Calculated route for active ride
    @State private var calculatedRoute: MKRoute?
    
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
            
            // Setup location callbacks for presence updates
            rideViewModel.setLocationCallbacks(
                getLatitude: { [weak locationManager] in
                    locationManager?.currentCoordinate?.latitude ?? 0
                },
                getLongitude: { [weak locationManager] in
                    locationManager?.currentCoordinate?.longitude ?? 0
                }
            )
            
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
                
                // Start watching Firebase requests when location is available
                if !hasInitialized {
                    hasInitialized = true
                    
                    // Always watch Firebase requests for real-time updates
                    requestService.watchOpenRequestsWithExpansion(
                        lat: coordinate.latitude,
                        lng: coordinate.longitude,
                        expandDelay: 20
                    )
                    
                    // Initialize dummy rides only with mock data enabled
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
        .onChange(of: requestService.activeRequest?.status) { _, newStatus in
            // If request was cancelled or completed externally, show confirmation or clean up
            if let status = newStatus {
                if status == .completed {
                    // Only show if we haven't already shown from our own confirmation
                    if !showPickupConfirmedAlert && confirmedBy.isEmpty {
                        confirmedBy = "pasajero"
                        showPickupConfirmedAlert = true
                    }
                } else if status == .cancelled {
                    stopDriverLocationUpdates()
                    requestService.stopWatchingRequest()
                    activeFirebaseRequest = nil
                }
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            stopDriverLocationUpdates()
        }
        .alert("¡Recogida Confirmada!", isPresented: $showPickupConfirmedAlert) {
            Button("¡Buen Viaje!") {
                stopDriverLocationUpdates()
                requestService.stopWatchingRequest()
                activeFirebaseRequest = nil
                clearRoute()
            }
        } message: {
            Text("La recogida ha sido confirmada por el \(confirmedBy).\n\n¡Que tengas un excelente viaje! Ya puedes cerrar la app.")
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Driver location
            UserAnnotation()
            
            // Route polyline (when active ride)
            if let route = calculatedRoute {
                MapPolyline(route.polyline)
                    .stroke(
                        BiciTaxiTheme.routeColor,
                        lineWidth: 6
                    )
            }
            
            // Active ride - show client pickup location
            if let activeRequest = activeFirebaseRequest ?? requestService.activeRequest {
                // Client pickup location (where to pick up the passenger)
                Annotation("Cliente", coordinate: CLLocationCoordinate2D(
                    latitude: activeRequest.pickup.lat,
                    longitude: activeRequest.pickup.lng
                )) {
                    ClientPickupAnnotationView()
                }
                
                // Client destination (optional, if provided)
                if let dropoff = activeRequest.dropoff {
                    Annotation("Destino", coordinate: CLLocationCoordinate2D(
                        latitude: dropoff.lat,
                        longitude: dropoff.lng
                    )) {
                        DestinationAnnotationView()
                    }
                }
            }
            
            // Pending ride requests (only when not on active ride)
            if activeFirebaseRequest == nil && requestService.activeRequest == nil {
                ForEach(rideViewModel.pendingRides) { ride in
                    Annotation(ride.pickup.shortDescription, coordinate: ride.pickup.coordinate) {
                        PendingRideAnnotationView(ride: ride)
                    }
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
                // Show active ride if there's one, otherwise show pending requests
                if let activeRequest = activeFirebaseRequest ?? requestService.activeRequest {
                    activeRideView(request: activeRequest)
                } else {
                    pendingRequestsView
                }
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
    
    /// Filter only fresh requests (heartbeat within 3 minutes)
    private var freshRequests: [RideRequest] {
        requestService.openRequests.filter { $0.isFresh }
    }
    
    private var pendingRequestsView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bicycle")
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
                
                Text("Solicitudes Cercanas: \(freshRequests.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                // Show expanded indicator
                if requestService.isWatchingExpanded {
                    Text("(9 celdas)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if !freshRequests.isEmpty {
                // Compact scrollable list of Firebase requests
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(freshRequests) { request in
                            compactFirebaseRequest(request)
                        }
                    }
                }
                .frame(maxHeight: 200)
            } else {
                Text("No hay solicitudes pendientes cerca")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    /// Compact Firebase request row
    private func compactFirebaseRequest(_ request: RideRequest) -> some View {
        HStack(spacing: 10) {
            // Age badge
            VStack(spacing: 2) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
                Text(request.ageString)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.primary)
            }
            .frame(width: 50)
            
            // Destination info
            VStack(alignment: .leading, spacing: 2) {
                // Geocoded name or "Destino"
                Text(request.dropoff?.address ?? "Solicitud de viaje")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Coordinates in compact DMS format
                if let dropoff = request.dropoff {
                    compactDMSText(lat: dropoff.lat, lng: dropoff.lng)
                }
            }
            
            Spacer()
            
            // Distance (if can calculate)
            if let dropoff = request.dropoff, let driverLoc = locationManager.currentCoordinate {
                let tripDist = calculateDistance(
                    lat1: request.pickup.lat, lng1: request.pickup.lng,
                    lat2: dropoff.lat, lng2: dropoff.lng
                )
                Text(formatDistanceMeters(tripDist))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
            }
            
            // Accept button
            Button {
                acceptFirebaseRequest(request)
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
    
    /// Accept a Firebase request
    private func acceptFirebaseRequest(_ request: RideRequest) {
        Task {
            guard let driverUid = requestService.currentUserId else { return }
            
            // Assign driver to the request
            await requestService.assignDriver(
                cellId: request.cellId,
                requestId: request.requestId,
                driverUid: driverUid
            )
            
            // Store as active request and start watching it
            await MainActor.run {
                activeFirebaseRequest = request
                requestService.watchRequest(cellId: request.cellId, requestId: request.requestId)
                startDriverLocationUpdates(for: request)
                calculateRoute(for: request)
            }
        }
    }
    
    /// Calculate route from driver's current location to pickup (and optionally to destination)
    private func calculateRoute(for request: RideRequest) {
        guard let driverLocation = locationManager.currentCoordinate else { return }
        
        let pickupCoord = CLLocationCoordinate2D(
            latitude: request.pickup.lat,
            longitude: request.pickup.lng
        )
        
        // Calculate route from driver to pickup
        let routeRequest = MKDirections.Request()
        routeRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: driverLocation))
        routeRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: pickupCoord))
        routeRequest.transportType = .walking
        routeRequest.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: routeRequest)
        
        Task {
            do {
                let response = try await directions.calculate()
                await MainActor.run {
                    if let route = response.routes.first {
                        calculatedRoute = route
                        // Zoom to show the route
                        zoomToRoute()
                    }
                }
            } catch {
                print("⚠️ Route calculation failed: \(error)")
            }
        }
    }
    
    /// Zoom camera to show the full route
    private func zoomToRoute() {
        guard let route = calculatedRoute else { return }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            let rect = route.polyline.boundingMapRect
            let paddedRect = rect.insetBy(dx: -rect.size.width * 0.3, dy: -rect.size.height * 0.3)
            cameraPosition = .rect(paddedRect)
        }
    }
    
    /// Start periodic driver location updates during active ride
    private func startDriverLocationUpdates(for request: RideRequest) {
        driverLocationTimer?.invalidate()
        driverLocationTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak locationManager] _ in
            guard let coordinate = locationManager?.currentCoordinate else { return }
            Task {
                await requestService.updateDriverLocation(
                    cellId: request.cellId,
                    requestId: request.requestId,
                    lat: coordinate.latitude,
                    lng: coordinate.longitude
                )
            }
        }
    }
    
    /// Stop driver location updates
    private func stopDriverLocationUpdates() {
        driverLocationTimer?.invalidate()
        driverLocationTimer = nil
    }
    
    /// Clear route and reset map
    private func clearRoute() {
        calculatedRoute = nil
    }
    
    /// Complete or cancel the active ride
    private func finishActiveRide(completed: Bool) {
        guard let request = activeFirebaseRequest ?? requestService.activeRequest else { return }
        
        if completed {
            // Set confirmedBy BEFORE calling complete to prevent race condition with onChange
            confirmedBy = "conductor"
            
            Task {
                await requestService.completeRequest(cellId: request.cellId, requestId: request.requestId)
                await MainActor.run {
                    showPickupConfirmedAlert = true
                }
            }
        } else {
            Task {
                await requestService.cancelRequest(cellId: request.cellId, requestId: request.requestId)
                await MainActor.run {
                    stopDriverLocationUpdates()
                    requestService.stopWatchingRequest()
                    activeFirebaseRequest = nil
                    clearRoute()
                }
            }
        }
    }
    
    // MARK: - Active Ride View
    
    /// View shown when conductor has an active ride
    private func activeRideView(request: RideRequest) -> some View {
        VStack(spacing: 0) {
            if isRideInfoCollapsed {
                // Collapsed view - just a button to expand
                collapsedRideInfoView(request: request)
            } else {
                // Expanded view - full ride info
                expandedRideInfoView(request: request)
            }
        }
    }
    
    /// Collapsed ride info - minimal button
    private func collapsedRideInfoView(request: RideRequest) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isRideInfoCollapsed = false
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bicycle")
                    .font(.title2)
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.clientName ?? "Cliente")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.primary)
                    
                    Text("Toca para ver detalles")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("ACTIVO")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.15))
                .clipShape(Capsule())
                
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    /// Expanded ride info - full details
    private func expandedRideInfoView(request: RideRequest) -> some View {
        VStack(spacing: 16) {
            // Header - Show passenger name with collapse button
            HStack {
                Image(systemName: "bicycle")
                    .font(.title2)
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Show passenger name
                    Text("Pasajero: \(request.clientName ?? "Cliente")")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.primary)
                    
                    Text("Dirígete al punto de recogida")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("ACTIVO")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.15))
                .clipShape(Capsule())
                
                // Collapse button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isRideInfoCollapsed = true
                    }
                    // Zoom to show the route when collapsed
                    zoomToRoute()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Pickup location
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Punto de recogida")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(request.pickup.address ?? "Ubicación del cliente")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // Dropoff location (if available)
            if let dropoff = request.dropoff {
                HStack(spacing: 12) {
                    Image(systemName: "flag.checkered")
                        .font(.title3)
                        .foregroundColor(.indigo)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Destino")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(dropoff.address ?? "Destino del viaje")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Action buttons
            HStack(spacing: 12) {
                // Cancel button
                Button {
                    finishActiveRide(completed: false)
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancelar")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Pickup complete button (app finishes intervention here)
                Button {
                    finishActiveRide(completed: true)
                } label: {
                    HStack {
                        Image(systemName: "person.fill.checkmark")
                        Text("Pasajero Recogido")
                    }
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
    
    /// Calculate distance using Haversine formula
    private func calculateDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
        let R = 6371000.0 // Earth radius in meters
        let lat1Rad = lat1 * .pi / 180
        let lat2Rad = lat2 * .pi / 180
        let deltaLat = (lat2 - lat1) * .pi / 180
        let deltaLng = (lng2 - lng1) * .pi / 180
        
        let a = sin(deltaLat/2) * sin(deltaLat/2) +
                cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng/2) * sin(deltaLng/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
    
    /// Format distance in meters/km
    private func formatDistanceMeters(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0fm", meters)
        }
        return String(format: "%.1fkm", meters / 1000)
    }
    
    /// Compact DMS text with minutes in lighter color, seconds in darker color
    /// Format: 47'33.6"N, 24'15.8"W (without degrees)
    private func compactDMSText(lat: Double, lng: Double) -> some View {
        let latDms = toDMSComponents(abs(lat))
        let lngDms = toDMSComponents(abs(lng))
        let latDir = lat >= 0 ? "N" : "S"
        let lngDir = lng >= 0 ? "E" : "W"
        
        let minuteColor = Color.primary.opacity(0.5) // 50% - lighter
        let secondColor = Color.primary.opacity(0.8) // 80% - darker
        
        return HStack(spacing: 0) {
            // Latitude: minutes (light) + seconds (dark)
            Text("\(latDms.minutes)'")
                .foregroundColor(minuteColor)
            Text(String(format: "%.1f\"%@", latDms.seconds, latDir))
                .foregroundColor(secondColor)
            
            Text(", ")
                .foregroundColor(minuteColor)
            
            // Longitude: minutes (light) + seconds (dark)
            Text("\(lngDms.minutes)'")
                .foregroundColor(minuteColor)
            Text(String(format: "%.1f\"%@", lngDms.seconds, lngDir))
                .foregroundColor(secondColor)
        }
        .font(.caption2.italic())
    }
    
    /// Convert decimal degrees to DMS components
    private func toDMSComponents(_ decimal: Double) -> (degrees: Int, minutes: Int, seconds: Double) {
        let degrees = Int(decimal)
        let minDecimal = (decimal - Double(degrees)) * 60
        let minutes = Int(minDecimal)
        let seconds = (minDecimal - Double(minutes)) * 60
        return (degrees, minutes, seconds)
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

// MARK: - Client Pickup Annotation (Active Ride)

struct ClientPickupAnnotationView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
                .frame(width: 44, height: 44)
                .shadow(color: Color.green.opacity(0.5), radius: 12)
            
            Image(systemName: "person.fill")
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .bold))
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 44, height: 44)
        )
    }
}

// MARK: - Destination Annotation (Active Ride)

struct DestinationAnnotationView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.indigo)
                .frame(width: 36, height: 36)
                .shadow(color: Color.indigo.opacity(0.5), radius: 8)
            
            Image(systemName: "flag.fill")
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
