//
//  LiquidGlassTabShell.swift
//  bicitaxi
//
//  iOS 26 Native TabView with Liquid Glass styling
//  Follows Apple HIG guidelines for tab bars
//

import SwiftUI

/// Main container view with iOS 26 Native TabView navigation
/// Uses native SwiftUI TabView with iOS 18+ Tab-based syntax
struct LiquidGlassTabShell: View {
    @State private var selectedTab: AppTab = .map  // Default to map
    @StateObject private var rideViewModel: ClientRideViewModel
    
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
        
    init(repo: any RideRepository) {
        _rideViewModel = StateObject(wrappedValue: ClientRideViewModel(repo: repo))
    }
    
    var body: some View {
        // Native iOS 26 TabView with Liquid Glass material (automatic)
        TabView(selection: $selectedTab) {
            // Map Tab
            Tab("Mapa", systemImage: "map.fill", value: .map) {
                ClientMapView(rideViewModel: rideViewModel)
                    .ignoresSafeArea(edges: .bottom)
            }
            
            // History Tab
            Tab("Historial", systemImage: "clock.arrow.circlepath", value: .history) {
                ClientHistoryView()
            }
            
            // Profile Tab
            Tab("Perfil", systemImage: "person.fill", value: .profile) {
                ProfileView(rideViewModel: rideViewModel)
            }
        }
        .tabViewStyle(.tabBarOnly)  // Standard tab bar, no sidebar adaptation
    }
}

#Preview {
    LiquidGlassTabShell(repo: InMemoryRideRepository())
}
