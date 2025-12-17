//
//  RequestListView.swift
//  bicitaxi-conductor
//
//  View that displays incoming ride requests for drivers.
//

import SwiftUI

/// View that displays incoming ride requests for drivers.
struct RequestListView: View {
    let lat: Double
    let lng: Double
    var onRequestTap: ((RideRequest) -> Void)?
    
    @StateObject private var requestService = RequestService()
    
    // Filter only fresh requests
    private var freshRequests: [RideRequest] {
        requestService.openRequests.filter { $0.isFresh }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            headerView
            
            // Request list
            if freshRequests.isEmpty {
                emptyStateView
            } else {
                ForEach(freshRequests) { request in
                    RequestCard(request: request, driverLat: lat, driverLng: lng)
                        .onTapGesture {
                            onRequestTap?(request)
                        }
                }
            }
        }
        .onAppear {
            requestService.watchOpenRequestsWithExpansion(lat: lat, lng: lng)
        }
        .onChange(of: lat) { _, newLat in
            requestService.watchOpenRequestsWithExpansion(lat: newLat, lng: lng)
        }
        .onChange(of: lng) { _, newLng in
            requestService.watchOpenRequestsWithExpansion(lat: lat, lng: newLng)
        }
    }
    
    private var headerView: some View {
        HStack {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            
            // Title and count
            VStack(alignment: .leading, spacing: 2) {
                Text("Solicitudes cercanas")
                    .font(.system(size: 16, weight: .semibold))
                
                HStack(spacing: 4) {
                    Text(requestService.isWatchingExpanded ? "9 celdas" : "1 celda")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 4, height: 4)
                    
                    Text("\(freshRequests.count) \(freshRequests.count == 1 ? "solicitud" : "solicitudes")")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Live indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                
                Text("EN VIVO")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.15))
            .clipShape(Capsule())
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Sin solicitudes")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(requestService.isWatchingExpanded
                 ? "No hay clientes buscando viaje en tu zona"
                 : "Expandiendo búsqueda en 20s...")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Card view for a single ride request with compact DMS format.
struct RequestCard: View {
    let request: RideRequest
    let driverLat: Double
    let driverLng: Double
    
    // Calculate distance to pickup
    private var distanceToPickup: Double {
        Self.calculateDistance(
            lat1: driverLat, lng1: driverLng,
            lat2: request.pickup.lat, lng2: request.pickup.lng
        )
    }
    
    // Calculate trip distance (pickup to dropoff)
    private var tripDistance: Double? {
        guard let dropoff = request.dropoff else { return nil }
        return Self.calculateDistance(
            lat1: request.pickup.lat, lng1: request.pickup.lng,
            lat2: dropoff.lat, lng2: dropoff.lng
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Age + Distance to pickup badge
            HStack {
                Text(request.ageString)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text(formatDistance(distanceToPickup))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.cyan.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            
            
            // Destination only - with geocoded name if available
            if let dropoff = request.dropoff {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.indigo)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Geocoded name (primary)
                        Text(dropoff.address ?? "Destino")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        // Compact DMS (secondary)
                        compactDMSText(lat: dropoff.lat, lng: dropoff.lng)
                    }
                    
                    Spacer()
                }
                
                // Trip distance row
                if let tripDist = tripDistance {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.system(size: 12))
                            .foregroundColor(.teal)
                        
                        Text("Distancia:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Text(formatDistance(tripDist))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.teal)
                    }
                }
            } else {
                // No dropoff - show pickup DMS only
                HStack(spacing: 8) {
                    Image(systemName: "circle.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    
                    Text("Recogida: ")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    compactDMSText(lat: request.pickup.lat, lng: request.pickup.lng)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Compact DMS Text
    
    /// Builds compact DMS text with minutes lighter, seconds darker
    private func compactDMSText(lat: Double, lng: Double) -> some View {
        let latDms = toDMS(abs(lat))
        let lngDms = toDMS(abs(lng))
        let latDir = lat >= 0 ? "N" : "S"
        let lngDir = lng >= 0 ? "E" : "W"
        
        return HStack(spacing: 0) {
            Text("\(latDms.minutes)'")
                .foregroundColor(.secondary)
            Text("\(latDms.seconds)\"\(latDir)")
                .foregroundColor(.primary)
                .fontWeight(.medium)
            Text(", ")
                .foregroundColor(.secondary)
            Text("\(lngDms.minutes)'")
                .foregroundColor(.secondary)
            Text("\(lngDms.seconds)\"\(lngDir)")
                .foregroundColor(.primary)
                .fontWeight(.medium)
        }
        .font(.system(size: 10))
        .italic()
    }
    
    // MARK: - Helpers
    
    private func toDMS(_ decimal: Double) -> (degrees: String, minutes: String, seconds: String) {
        let deg = Int(decimal)
        let minDecimal = (decimal - Double(deg)) * 60
        let min = Int(minDecimal)
        let sec = (minDecimal - Double(min)) * 60
        
        return (
            degrees: String(deg),
            minutes: String(format: "%02d", min),
            seconds: String(format: "%.1f", sec)
        )
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
    
    static func calculateDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
        let earthRadius = 6371000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLng = (lng2 - lng1) * .pi / 180
        let lat1Rad = lat1 * .pi / 180
        let lat2Rad = lat2 * .pi / 180
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) * sin(dLng / 2) * sin(dLng / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
}

#Preview {
    ScrollView {
        RequestListView(lat: 4.7410, lng: -74.0721)
            .padding()
    }
    .background(Color.gray.opacity(0.1))
}
