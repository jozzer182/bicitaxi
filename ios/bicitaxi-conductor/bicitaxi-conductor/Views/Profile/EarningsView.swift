//
//  EarningsView.swift
//  bicitaxi-conductor
//
//  Driver earnings and completed rides view
//

import SwiftUI

struct EarningsView: View {
    @ObservedObject var rideViewModel: DriverRideViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Earnings header
                earningsHeader
                
                // Stats card
                statsCard
                
                // Completed rides
                completedRidesSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
        }
        .scrollContentBackground(.hidden)
        .background(.clear)
        .task {
            await rideViewModel.loadCompletedRides()
        }
    }
    
    // MARK: - Earnings Header
    
    private var earningsHeader: some View {
        VStack(spacing: 16) {
            Text("Ganancias de Hoy")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(BiciTaxiTheme.formatCOP(rideViewModel.totalEarnings))
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(BiciTaxiTheme.accentGradient)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 24)
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        HStack(spacing: 20) {
            statItem(
                value: "\(rideViewModel.completedRides.count)",
                label: "Viajes"
            )
            
            Divider()
                .frame(height: 40)
                .background(Color.secondary.opacity(0.3))
            
            statItem(
                value: BiciTaxiTheme.formatCOP(averageFare),
                label: "Tarifa Prom."
            )
            
            Divider()
                .frame(height: 40)
                .background(Color.secondary.opacity(0.3))
            
            statItem(
                value: rideViewModel.isOnline ? "En Línea" : "Desconectado",
                label: "Estado"
            )
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var averageFare: Int {
        guard !rideViewModel.completedRides.isEmpty else { return 0 }
        return rideViewModel.totalEarnings / rideViewModel.completedRides.count
    }
    
    // MARK: - Completed Rides
    
    private var completedRidesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Viajes Completados")
                .font(.headline)
                .foregroundColor(.primary)
            
            if rideViewModel.completedRides.isEmpty {
                emptyState
            } else {
                ForEach(rideViewModel.completedRides) { ride in
                    completedRideRow(ride)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bicycle")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("Aún no hay viajes completados")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private func completedRideRow(_ ride: Ride) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("Completado")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                }
                
                Text(ride.pickup.shortDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(ride.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            Spacer()
            
            Text("+\(BiciTaxiTheme.formatCOP(ride.estimatedFare))")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.green)
        }
        .padding(16)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ZStack {
        BiciTaxiTheme.background.ignoresSafeArea()
        EarningsView(rideViewModel: DriverRideViewModel(repo: InMemoryRideRepository()))
    }
    .preferredColorScheme(.light)
}
