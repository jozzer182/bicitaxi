//
//  ClientHistoryView.swift
//  bicitaxi
//
//  Full history view with Firebase integration
//

import SwiftUI

/// Client ride history view showing past rides from Firebase
struct ClientHistoryView: View {
    @StateObject private var historyService = HistoryService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Historial de viajes")
                    .font(.title2.weight(.bold))
                    .padding(.horizontal)
                
                Text(historyService.isLoading ? "Cargando..." : "\(historyService.history.count) viajes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                if historyService.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if historyService.history.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(historyService.history) { ride in
                            RideHistoryCard(ride: ride, isDriver: false)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top)
        }
        .background(.regularMaterial)
        .refreshable {
            await historyService.fetchHistory()
        }
        .task {
            await historyService.fetchHistory()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("Sin viajes aún")
                .font(.headline)
            
            Text("Cuando realices viajes, aparecerán aquí")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}

/// Card displaying a single ride history entry
struct RideHistoryCard: View {
    let ride: RideHistoryEntry
    let isDriver: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status and date
            HStack {
                statusBadge
                Spacer()
                Text(ride.dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Other party info (show driver for client, client for driver)
            if isDriver {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundStyle(.tint)
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ride.clientName)
                            .font(.subheadline.weight(.semibold))
                        Text("Pasajero")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let driverName = ride.driverName {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "bicycle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(driverName)
                            .font(.subheadline.weight(.semibold))
                        Text("Conductor")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Route
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.green)
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 2, height: 20)
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(ride.pickupAddress ?? "Punto de recogida")
                        .font(.subheadline)
                    Text(ride.dropoffAddress ?? "Sin destino")
                        .font(.subheadline)
                }
            }
            
            Divider()
            
            // Time
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ride.timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var statusBadge: some View {
        let (color, text) = switch ride.status {
        case "completed": (Color.green, "Completado")
        case "cancelled": (Color.red, "Cancelado")
        case "assigned": (Color.orange, "En curso")
        default: (Color.gray, "Pendiente")
        }
        
        return Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }
}

#Preview {
    ClientHistoryView()
}
