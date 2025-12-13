//
//  LiquidGlassTabShell.swift
//  bicitaxi-conductor
//
//  iOS 26 Native TabView with Liquid Glass styling
//  Follows Apple HIG guidelines for tab bars
//

import SwiftUI

/// Main container view with iOS 26 Native TabView navigation
/// Uses native SwiftUI TabView with iOS 18+ Tab-based syntax
struct LiquidGlassTabShell: View {
    @State private var selectedTab: AppTab = .map  // Default to map
    @StateObject private var rideViewModel: DriverRideViewModel
    
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
        
    init(repo: InMemoryRideRepository) {
        _rideViewModel = StateObject(wrappedValue: DriverRideViewModel(repo: repo))
    }
    
    var body: some View {
        // Native iOS 26 TabView with Liquid Glass material (automatic)
        TabView(selection: $selectedTab) {
            // Map Tab
            Tab("Mapa", systemImage: "map.fill", value: .map) {
                DriverHomeView(rideViewModel: rideViewModel)
                    .ignoresSafeArea(edges: .bottom)
            }
            
            // Active Ride Tab
            Tab("Viaje", systemImage: "bicycle", value: .activeRide) {
                DriverActiveRideView(rideViewModel: rideViewModel, onComplete: {
                    selectedTab = .map  // Return to map after ride
                })
            }
            
            // Earnings Tab
            Tab("Ganancias", systemImage: "dollarsign.circle.fill", value: .earnings) {
                EarningsView(rideViewModel: rideViewModel)
            }
            
            // Profile Tab
            Tab("Perfil", systemImage: "person.fill", value: .profile) {
                DriverProfileView(rideViewModel: rideViewModel)
            }
        }
        .tabViewStyle(.tabBarOnly)  // Standard tab bar, no sidebar adaptation
        .onChange(of: rideViewModel.activeRide) { _, newRide in
            // Switch to Active Ride tab when a ride is accepted
            if newRide != nil && selectedTab != .activeRide {
                withAnimation {
                    selectedTab = .activeRide
                }
            }
        }
    }
}

#Preview {
    LiquidGlassTabShell(repo: InMemoryRideRepository())
}
