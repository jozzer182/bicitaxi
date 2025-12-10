//
//  LiquidGlassTabShell.swift
//  bicitaxi-conductor
//
//  iOS 26 Native Liquid Glass Container with tab navigation
//

import SwiftUI

/// Main container view with iOS 26 Native Liquid Glass tab navigation
struct LiquidGlassTabShell: View {
    @State private var selectedTab: AppTab = .map  // Default to map
    @StateObject private var rideViewModel: DriverRideViewModel
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(repo: InMemoryRideRepository) {
        _rideViewModel = StateObject(wrappedValue: DriverRideViewModel(repo: repo))
    }
    
    var body: some View {
        // Wrap in GlassEffectContainer for morphing animations
        GlassEffectContainer {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Map always visible as background for liquid glass effect
                    DriverHomeView(rideViewModel: rideViewModel)
                        .ignoresSafeArea()
                    
                    // Light frosted overlay for non-map tabs - reduced blur to show map
                    if selectedTab != .map {
                        Color.white
                            .opacity(0.75)
                            .blur(radius: 3)
                            .ignoresSafeArea()
                            .transition(.opacity)
                    }
                    
                    // Content overlay for non-map tabs
                    if selectedTab != .map {
                        contentOverlay(geometry: geometry)
                    }
                    
                    // Native Liquid Glass tab bar
                    tabBar(geometry: geometry)
                }
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
        }
        .onChange(of: rideViewModel.activeRide) { _, newRide in
            // Switch to Active Ride tab when a ride is accepted
            if newRide != nil && selectedTab != .activeRide {
                withAnimation {
                    selectedTab = .activeRide
                }
            }
        }
    }
    
    // MARK: - Content
    
    /// Content overlay for non-map tabs (with glass background)
    @ViewBuilder
    private func contentOverlay(geometry: GeometryProxy) -> some View {
        switch selectedTab {
        case .map:
            EmptyView()
        case .activeRide:
            DriverActiveRideView(rideViewModel: rideViewModel, onComplete: {
                selectedTab = .map  // Return to map after ride
            })
            .padding(.bottom, tabBarPadding)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        case .earnings:
            EarningsView(rideViewModel: rideViewModel)
                .padding(.bottom, tabBarPadding)
                .transition(.move(edge: .trailing).combined(with: .opacity))
        case .profile:
            DriverProfileView(rideViewModel: rideViewModel)
                .padding(.bottom, tabBarPadding)
                .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }
    
    /// Switch content based on selected tab - kept for backwards compatibility
    @ViewBuilder
    private func contentView(geometry: GeometryProxy) -> some View {
        switch selectedTab {
        case .map:
            // Map extends to bottom edge for glass blur effect
            DriverHomeView(rideViewModel: rideViewModel)
                .ignoresSafeArea(edges: .bottom)
                .transition(.opacity)
        case .activeRide:
            DriverActiveRideView(rideViewModel: rideViewModel, onComplete: {
                selectedTab = .map  // Return to map after ride
            })
                .padding(.bottom, tabBarPadding)
                .transition(.opacity)
        case .earnings:
            EarningsView(rideViewModel: rideViewModel)
                .padding(.bottom, tabBarPadding)
                .transition(.opacity)
        case .profile:
            DriverProfileView(rideViewModel: rideViewModel)
                .padding(.bottom, tabBarPadding)
                .transition(.opacity)
        }
    }
    
    // MARK: - Tab Bar
    
    /// Tab bar with responsive sizing
    private func tabBar(geometry: GeometryProxy) -> some View {
        let isCompact = horizontalSizeClass == .compact
        let horizontalPadding: CGFloat = isCompact ? 16 : max(geometry.size.width * 0.15, 40)
        
        return LiquidGlassTabBar(selectedTab: $selectedTab)
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 8 : 16)
    }
    
    /// Bottom padding for content to make room for tab bar
    private var tabBarPadding: CGFloat {
        100 // Tab bar height + bottom safe area
    }
}

#Preview {
    LiquidGlassTabShell(repo: InMemoryRideRepository())
}
