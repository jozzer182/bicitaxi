//
//  GeoCellDebugView.swift
//  bicitaxi
//
//  Debug view for testing GeoCellService cross-platform consistency.
//

import SwiftUI

/// Debug view for testing GeoCellService cross-platform consistency.
struct GeoCellDebugView: View {
    @State private var latText: String = "4.7410"
    @State private var lngText: String = "-74.0721"
    @State private var canonical: String = ""
    @State private var cellId: String = ""
    @State private var neighborCanonicals: [String] = []
    @State private var neighborCellIds: [String] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Input section
                    inputSection
                    
                    // Results section
                    if !canonical.isEmpty {
                        currentCellSection
                        neighborsSection
                    }
                    
                    // Instructions
                    instructionsSection
                }
                .padding()
            }
            .navigationTitle("GeoCellService Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: runAllTests) {
                        Image(systemName: "play.fill")
                    }
                }
            }
            .onAppear {
                computeCell()
            }
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Input Coordinates")
                .font(.headline)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Latitude")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Latitude", text: $latText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .onChange(of: latText) { _, _ in computeCell() }
                }
                
                VStack(alignment: .leading) {
                    Text("Longitude")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Longitude", text: $lngText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .onChange(of: lngText) { _, _ in computeCell() }
                }
            }
            
            // Quick test buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    quickButton("Suba", lat: 4.7410, lng: -74.0721)
                    quickButton("Equator", lat: 0.5, lng: 0.5)
                    quickButton("Buenos Aires", lat: -34.6037, lng: -58.3816)
                    quickButton("Madrid", lat: 40.4168, lng: -3.7038)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private var currentCellSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Cell")
                .font(.headline)
            
            resultRow(label: "Canonical", value: canonical)
            resultRow(label: "Cell ID", value: cellId)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var neighborsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("8 Neighbor Cells")
                .font(.headline)
            
            ForEach(0..<neighborCanonicals.count, id: \.self) { i in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Neighbor \(i)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(neighborCanonicals[i])
                        .font(.system(size: 11, design: .monospaced))
                    
                    Text(neighborCellIds[i])
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.orange)
                Text("Cross-Platform Verification")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text("""
            1. Run this view on iOS
            2. Run GeoCellTestVectors.runAllTests() on Flutter
            3. Compare canonical strings and cell IDs
            4. They must be IDENTICAL for each test vector
            """)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func quickButton(_ label: String, lat: Double, lng: Double) -> some View {
        Button(action: {
            latText = String(lat)
            lngText = String(lng)
            computeCell()
        }) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
    }
    
    private func resultRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(value)
                    .font(.system(size: 12, design: .monospaced))
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = value
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func computeCell() {
        guard let lat = Double(latText),
              let lng = Double(lngText) else {
            canonical = ""
            cellId = ""
            neighborCanonicals = []
            neighborCellIds = []
            return
        }
        
        canonical = GeoCellService.computeCanonical(lat: lat, lng: lng)
        cellId = GeoCellService.computeCellId(canonical: canonical)
        neighborCanonicals = GeoCellService.computeNeighborCanonicals(lat: lat, lng: lng)
        neighborCellIds = neighborCanonicals.map { GeoCellService.computeCellId(canonical: $0) }
        
        // Print to console for debugging
        GeoCellService.debugPrint(lat: lat, lng: lng)
    }
    
    private func runAllTests() {
        print("\n" + String(repeating: "=", count: 60))
        print("iOS GEO CELL TEST VECTORS")
        print(String(repeating: "=", count: 60) + "\n")
        GeoCellTestVectors.runAllTests()
    }
}

#Preview {
    GeoCellDebugView()
}
