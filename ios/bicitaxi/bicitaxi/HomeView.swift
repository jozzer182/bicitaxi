//
//  HomeView.swift
//  bicitaxi
//
//  Home tab view with ride status
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var rideViewModel: ClientRideViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome header
                welcomeHeader
                
                // Active ride card (if any)
                if let ride = rideViewModel.activeRide {
                    activeRideCard(ride)
                }
                
                // Quick action card
                quickActionCard
                
                // Recent rides
                if !rideViewModel.history.isEmpty {
                    recentRidesSection
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
        }
        .task {
            await rideViewModel.loadHistory()
        }
    }
    
    // MARK: - Welcome Header
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title.weight(.bold))
                .foregroundColor(.white)
            
            Text("Ready for your next ride?")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Active Ride Card
    
    private func activeRideCard(_ ride: Ride) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: ride.status.iconName)
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
                
                Text(ride.status.displayText)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(ride.pickup.shortDescription, systemImage: "figure.wave")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if let dropoff = ride.dropoff {
                        Label(dropoff.shortDescription, systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Text(BiciTaxiTheme.formatCOP(ride.estimatedFare))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }
    
    // MARK: - Quick Action Card
    
    private var quickActionCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "bicycle")
                .font(.system(size: 40))
                .foregroundStyle(BiciTaxiTheme.accentGradient)
            
            Text("Request a Ride")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Tap the Map tab to select your pickup and dropoff locations")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 20)
    }
    
    // MARK: - Recent Rides
    
    private var recentRidesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Rides")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(rideViewModel.history.prefix(3)) { ride in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ride.pickup.shortDescription)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text(ride.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text(BiciTaxiTheme.formatCOP(ride.estimatedFare))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

#Preview {
    ZStack {
        BiciTaxiTheme.background.ignoresSafeArea()
        HomeView(rideViewModel: ClientRideViewModel(repo: InMemoryRideRepository()))
    }
    .preferredColorScheme(.dark)
}
