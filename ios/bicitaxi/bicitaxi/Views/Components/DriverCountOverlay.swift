//
//  DriverCountOverlay.swift
//  bicitaxi
//
//  Overlay component that shows the count of nearby drivers in real-time.
//

import SwiftUI
import Combine

/// Overlay view that shows the count of nearby drivers in real-time.
struct DriverCountOverlay: View {
    let lat: Double
    let lng: Double
    
    @StateObject private var presenceService = PresenceService(
        appName: "bicitaxi",
        role: .client
    )
    
    /// Timer to periodically refresh and re-evaluate stale drivers
    /// This is needed because Firestore only emits when documents change
    let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(presenceService.driverCount > 0 
                          ? Color.green.opacity(0.2)
                          : Color.gray.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "bicycle")
                    .font(.system(size: 14))
                    .foregroundColor(presenceService.driverCount > 0 ? .green : .gray)
            }
            
            // Count and label
            VStack(alignment: .leading, spacing: 2) {
                Text("\(presenceService.driverCount) \(presenceService.driverCount == 1 ? "conductor" : "conductores")")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(presenceService.driverCount > 0 ? .primary : .secondary)
                
                Text("en tu zona")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            // Live indicator
            if presenceService.driverCount > 0 {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: .green.opacity(0.5), radius: 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            print("🗺️ DriverCountOverlay onAppear: lat=\(lat), lng=\(lng)")
            presenceService.watchDriverCount(lat: lat, lng: lng)
        }
        .onChange(of: lat) { _, newLat in
            print("🗺️ DriverCountOverlay lat changed: \(newLat)")
            presenceService.watchDriverCount(lat: newLat, lng: lng)
        }
        .onChange(of: lng) { _, newLng in
            print("🗺️ DriverCountOverlay lng changed: \(newLng)")
            presenceService.watchDriverCount(lat: lat, lng: newLng)
        }
        .onReceive(refreshTimer) { _ in
            // Periodic refresh to re-evaluate stale drivers
            presenceService.watchDriverCount(lat: lat, lng: lng)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
        DriverCountOverlay(lat: 4.7410, lng: -74.0721)
    }
}
