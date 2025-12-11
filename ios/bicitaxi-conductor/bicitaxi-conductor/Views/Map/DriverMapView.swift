//
//  DriverMapView.swift
//  bicitaxi-conductor
//
//  Map view for driver to see nearby ride requests
//

import SwiftUI
import MapKit

/// Represents a nearby ride request
struct RideRequest: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let estimatedFare: Int  // Colombian Pesos
}

/// Driver map view with nearby ride requests
struct DriverMapView: View {
    @StateObject private var locationManager = LocationManager()
    
    /// Driver online/offline status
    @State private var isOnline: Bool = true
    
    /// Nearby ride requests (dummy data)
    @State private var nearbyRequests: [RideRequest] = []
    
    /// Selected request for highlighting
    @State private var selectedRequest: RideRequest?
    
    /// Map camera position
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    /// Default region (Mexico City as fallback)
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Map
                mapView
                
                // Liquid Glass overlay panel
                overlayPanel(geometry: geometry)
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
                // Generate dummy requests around driver location
                generateDummyRequests(around: coordinate)
            }
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Driver location
            UserAnnotation()
            
            // Nearby ride requests
            ForEach(nearbyRequests) { request in
                Annotation(request.title, coordinate: request.coordinate) {
                    RideRequestAnnotationView(
                        request: request,
                        isSelected: selectedRequest?.id == request.id
                    )
                    .onTapGesture {
                        selectRequest(request)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Overlay Panel
    
    private func overlayPanel(geometry: GeometryProxy) -> some View {
        let isCompact = horizontalSizeClass == .compact
        let panelWidth = isCompact ? geometry.size.width - 32 : min(geometry.size.width * 0.6, 400)
        
        return VStack(spacing: 16) {
            // Driver status toggle
            driverStatusToggle
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Status info
            statusView
            
            // Accept button (when request selected)
            if selectedRequest != nil {
                acceptButton
            }
        }
        .padding(20)
        .frame(width: panelWidth)
        .glassCard(cornerRadius: 24)
        .padding(.horizontal, isCompact ? 16 : 0)
        .padding(.bottom, 120) // Space for tab bar
    }
    
    // MARK: - Driver Status Toggle
    
    private var driverStatusToggle: some View {
        HStack {
            Text("Driver Status")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                toggleOnlineStatus()
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(isOnline ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                    
                    Text(isOnline ? "Online" : "Offline")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isOnline ? .green : .gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Status View
    
    @ViewBuilder
    private var statusView: some View {
        if let error = locationManager.errorMessage {
            // Error state
            HStack(spacing: 12) {
                Image(systemName: "location.slash.fill")
                    .foregroundColor(.orange)
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        } else if locationManager.isLocating {
            // Loading state
            HStack(spacing: 12) {
                ProgressView()
                    .tint(.white)
                Text("Finding your location...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        } else if !isOnline {
            // Offline state
            HStack(spacing: 12) {
                Image(systemName: "moon.fill")
                    .foregroundColor(.gray)
                Text("You are offline. Go online to receive ride requests.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
        } else if let selected = selectedRequest {
            // Request selected
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "figure.wave")
                        .foregroundStyle(BiciTaxiTheme.accentGradient)
                    Text(selected.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(BiciTaxiTheme.formatCOP(selected.estimatedFare))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(BiciTaxiTheme.accentGradient)
                }
                
                Text("Tap 'Accept' to start this ride")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        } else {
            // Online, no selection
            HStack(spacing: 12) {
                Image(systemName: "bicycle")
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nearby Requests: \(nearbyRequests.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                    
                    Text("Tap a pin to see details")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Accept Button
    
    private var acceptButton: some View {
        HStack(spacing: 12) {
            Button {
                cancelSelection()
            } label: {
                Text("Cancel")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Button {
                acceptRequest()
            } label: {
                Text("Accept Ride")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(BiciTaxiTheme.accentGradient)
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleOnlineStatus() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isOnline.toggle()
            if !isOnline {
                selectedRequest = nil
            }
        }
    }
    
    private func selectRequest(_ request: RideRequest) {
        guard isOnline else { return }
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedRequest = request
        }
    }
    
    private func cancelSelection() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedRequest = nil
        }
    }
    
    private func acceptRequest() {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        // Log for now - will be wired to ride flow in Prompt 4
        if let request = selectedRequest {
            print("✅ Ride accepted:")
            print("   \(request.title)")
            print("   Location: \(request.coordinate.latitude), \(request.coordinate.longitude)")
            print("   Fare: $\(request.estimatedFare)")
        }
        
        selectedRequest = nil
    }
    
    private func generateDummyRequests(around center: CLLocationCoordinate2D) {
        guard nearbyRequests.isEmpty else { return }
        
        let offsets: [(Double, Double, String, Int)] = [
            (0.003, 0.002, "Solicitud de Viaje #1", 12500),
            (-0.002, 0.004, "Solicitud de Viaje #2", 8000),
            (0.004, -0.003, "Solicitud de Viaje #3", 18000),
            (-0.001, -0.002, "Solicitud de Viaje #4", 6500),
        ]
        
        nearbyRequests = offsets.map { offset in
            RideRequest(
                coordinate: CLLocationCoordinate2D(
                    latitude: center.latitude + offset.0,
                    longitude: center.longitude + offset.1
                ),
                title: offset.2,
                estimatedFare: offset.3
            )
        }
    }
}

// MARK: - Ride Request Annotation View

struct RideRequestAnnotationView: View {
    let request: RideRequest
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Pulse effect when selected
            if isSelected {
                Circle()
                    .fill(BiciTaxiTheme.accentPrimary.opacity(0.3))
                    .frame(width: 48, height: 48)
            }
            
            Circle()
                .fill(isSelected ? BiciTaxiTheme.accentPrimary : Color.orange)
                .frame(width: 36, height: 36)
                .shadow(color: (isSelected ? BiciTaxiTheme.accentPrimary : Color.orange).opacity(0.5), radius: 8)
            
            Image(systemName: "figure.wave")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .bold))
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    ZStack {
        BiciTaxiTheme.background.ignoresSafeArea()
        DriverMapView()
    }
    .preferredColorScheme(.light)
}
