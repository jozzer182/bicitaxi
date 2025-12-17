//
//  GeoCellService.swift
//  bicitaxi-conductor
//
//  Deterministic geographic cell service for presence/request system.
//  Uses 30 arc-second grid cells with canonical string format.
//  Produces identical results on Flutter and iOS platforms.
//

import Foundation

/// Deterministic geographic cell service for presence/request system.
struct GeoCellService {
    
    /// Default step size in arc-seconds (30")
    static let defaultStepSeconds: Int = 30
    
    // MARK: - Canonical String Computation
    
    /// Computes the canonical string for a geographic cell.
    ///
    /// Format: LAT_HEMI + latDeg(2) + "_" + latMin(2) + "_" + latSec(2) + "_" +
    ///         LON_HEMI + lonDeg(3) + "_" + lonMin(2) + "_" + lonSec(2) + "_s" + stepSec(2)
    ///
    /// Example: N04_44_30_W074_04_30_s30
    static func computeCanonical(lat: Double, lng: Double, stepSeconds: Int = defaultStepSeconds) -> String {
        // Determine hemispheres
        let latHemi = lat >= 0 ? "N" : "S"
        let lonHemi = lng >= 0 ? "E" : "W"
        
        // Convert to absolute values for DMS breakdown
        let latAbs = abs(lat)
        let lonAbs = abs(lng)
        
        // Convert to total seconds (integer arithmetic to avoid floating point errors)
        let latTotalSeconds = Int(floor(latAbs * 3600))
        let lonTotalSeconds = Int(floor(lonAbs * 3600))
        
        // Floor to step boundary (aligned to south-west corner)
        let latBucketSeconds = (latTotalSeconds / stepSeconds) * stepSeconds
        let lonBucketSeconds = (lonTotalSeconds / stepSeconds) * stepSeconds
        
        // Convert bucket seconds back to DMS
        let latDeg = latBucketSeconds / 3600
        let latMin = (latBucketSeconds % 3600) / 60
        let latSec = latBucketSeconds % 60
        
        let lonDeg = lonBucketSeconds / 3600
        let lonMin = (lonBucketSeconds % 3600) / 60
        let lonSec = lonBucketSeconds % 60
        
        // Format with proper padding
        let latDegStr = String(format: "%02d", latDeg)
        let latMinStr = String(format: "%02d", latMin)
        let latSecStr = String(format: "%02d", latSec)
        
        let lonDegStr = String(format: "%03d", lonDeg)
        let lonMinStr = String(format: "%02d", lonMin)
        let lonSecStr = String(format: "%02d", lonSec)
        
        let stepStr = String(format: "%02d", stepSeconds)
        
        return "\(latHemi)\(latDegStr)_\(latMinStr)_\(latSecStr)_\(lonHemi)\(lonDegStr)_\(lonMinStr)_\(lonSecStr)_s\(stepStr)"
    }
    
    // MARK: - Cell ID Computation
    
    /// Computes the Base64url-encoded cell ID from a canonical string.
    static func computeCellId(canonical: String) -> String {
        guard let data = canonical.data(using: .utf8) else { return "" }
        var base64Str = data.base64EncodedString()
        
        // Convert to URL-safe Base64
        base64Str = base64Str.replacingOccurrences(of: "+", with: "-")
        base64Str = base64Str.replacingOccurrences(of: "/", with: "_")
        base64Str = base64Str.replacingOccurrences(of: "=", with: "")
        
        return base64Str
    }
    
    /// Computes the cell ID directly from lat/lng coordinates.
    static func computeCellIdFromCoords(lat: Double, lng: Double, stepSeconds: Int = defaultStepSeconds) -> String {
        let canonical = computeCanonical(lat: lat, lng: lng, stepSeconds: stepSeconds)
        return computeCellId(canonical: canonical)
    }
    
    // MARK: - Cell Origin
    
    struct CellOrigin {
        let latSeconds: Int
        let lonSeconds: Int
        let latHemi: String
        let lonHemi: String
    }
    
    private static func getCellOrigin(lat: Double, lng: Double, stepSeconds: Int = defaultStepSeconds) -> CellOrigin {
        let latHemi = lat >= 0 ? "N" : "S"
        let lonHemi = lng >= 0 ? "E" : "W"
        
        let latAbs = abs(lat)
        let lonAbs = abs(lng)
        
        let latTotalSeconds = Int(floor(latAbs * 3600))
        let lonTotalSeconds = Int(floor(lonAbs * 3600))
        
        let latBucketSeconds = (latTotalSeconds / stepSeconds) * stepSeconds
        let lonBucketSeconds = (lonTotalSeconds / stepSeconds) * stepSeconds
        
        return CellOrigin(
            latSeconds: latBucketSeconds,
            lonSeconds: lonBucketSeconds,
            latHemi: latHemi,
            lonHemi: lonHemi
        )
    }
    
    private static func secondsToCanonical(
        latSeconds: Int, latHemi: String,
        lonSeconds: Int, lonHemi: String,
        stepSeconds: Int
    ) -> String {
        let latDeg = latSeconds / 3600
        let latMin = (latSeconds % 3600) / 60
        let latSec = latSeconds % 60
        
        let lonDeg = lonSeconds / 3600
        let lonMin = (lonSeconds % 3600) / 60
        let lonSec = lonSeconds % 60
        
        let latDegStr = String(format: "%02d", latDeg)
        let latMinStr = String(format: "%02d", latMin)
        let latSecStr = String(format: "%02d", latSec)
        
        let lonDegStr = String(format: "%03d", lonDeg)
        let lonMinStr = String(format: "%02d", lonMin)
        let lonSecStr = String(format: "%02d", lonSec)
        
        let stepStr = String(format: "%02d", stepSeconds)
        
        return "\(latHemi)\(latDegStr)_\(latMinStr)_\(latSecStr)_\(lonHemi)\(lonDegStr)_\(lonMinStr)_\(lonSecStr)_s\(stepStr)"
    }
    
    // MARK: - Hemisphere Handling
    
    struct AdjustedSeconds {
        let seconds: Int
        let hemi: String
    }
    
    private static func adjustSeconds(
        seconds: Int, hemi: String, delta: Int, maxSeconds: Int
    ) -> AdjustedSeconds {
        var newSeconds = seconds + delta
        var newHemi = hemi
        
        if newSeconds < 0 {
            newSeconds = -newSeconds
            newHemi = flipHemi(hemi)
        } else if newSeconds >= maxSeconds {
            newSeconds = maxSeconds - 1
        }
        
        return AdjustedSeconds(seconds: newSeconds, hemi: newHemi)
    }
    
    private static func flipHemi(_ hemi: String) -> String {
        switch hemi {
        case "N": return "S"
        case "S": return "N"
        case "E": return "W"
        case "W": return "E"
        default: return hemi
        }
    }
    
    // MARK: - Neighbor Computation
    
    static func computeNeighborCanonicals(lat: Double, lng: Double, stepSeconds: Int = defaultStepSeconds) -> [String] {
        let origin = getCellOrigin(lat: lat, lng: lng, stepSeconds: stepSeconds)
        var neighbors: [String] = []
        
        let deltas: [(Int, Int)] = [
            (-stepSeconds, -stepSeconds),
            (-stepSeconds, 0),
            (-stepSeconds, stepSeconds),
            (0, -stepSeconds),
            (0, stepSeconds),
            (stepSeconds, -stepSeconds),
            (stepSeconds, 0),
            (stepSeconds, stepSeconds)
        ]
        
        for (latDelta, lonDelta) in deltas {
            let adjustedLat = adjustSeconds(
                seconds: origin.latSeconds,
                hemi: origin.latHemi,
                delta: latDelta,
                maxSeconds: 90 * 3600
            )
            let adjustedLon = adjustSeconds(
                seconds: origin.lonSeconds,
                hemi: origin.lonHemi,
                delta: lonDelta,
                maxSeconds: 180 * 3600
            )
            
            let canonical = secondsToCanonical(
                latSeconds: adjustedLat.seconds,
                latHemi: adjustedLat.hemi,
                lonSeconds: adjustedLon.seconds,
                lonHemi: adjustedLon.hemi,
                stepSeconds: stepSeconds
            )
            neighbors.append(canonical)
        }
        
        return neighbors
    }
    
    static func computeNeighborCellIds(lat: Double, lng: Double, stepSeconds: Int = defaultStepSeconds) -> [String] {
        return computeNeighborCanonicals(lat: lat, lng: lng, stepSeconds: stepSeconds)
            .map { computeCellId(canonical: $0) }
    }
    
    static func computeAllCellIds(lat: Double, lng: Double, stepSeconds: Int = defaultStepSeconds) -> [String] {
        let currentCellId = computeCellIdFromCoords(lat: lat, lng: lng, stepSeconds: stepSeconds)
        let neighborIds = computeNeighborCellIds(lat: lat, lng: lng, stepSeconds: stepSeconds)
        return [currentCellId] + neighborIds
    }
    
    static func computeAllCanonicals(lat: Double, lng: Double, stepSeconds: Int = defaultStepSeconds) -> [String] {
        let currentCanonical = computeCanonical(lat: lat, lng: lng, stepSeconds: stepSeconds)
        let neighborCanonicals = computeNeighborCanonicals(lat: lat, lng: lng, stepSeconds: stepSeconds)
        return [currentCanonical] + neighborCanonicals
    }
    
    // MARK: - Debug
    
    static func debugPrint(lat: Double, lng: Double, stepSeconds: Int = defaultStepSeconds) {
        let canonical = computeCanonical(lat: lat, lng: lng, stepSeconds: stepSeconds)
        let cellId = computeCellId(canonical: canonical)
        let neighborCanonicals = computeNeighborCanonicals(lat: lat, lng: lng, stepSeconds: stepSeconds)
        let neighborCellIds = neighborCanonicals.map { computeCellId(canonical: $0) }
        
        print("=== GeoCellService Debug ===")
        print("Input: lat=\(lat), lng=\(lng), step=\(stepSeconds)s")
        print("Canonical: \(canonical)")
        print("CellId: \(cellId)")
        print("Neighbors:")
        for (i, canonical) in neighborCanonicals.enumerated() {
            print("  [\(i)] \(canonical) -> \(neighborCellIds[i])")
        }
        print("============================")
    }
}

// MARK: - Test Vectors

struct GeoCellTestVectors {
    static let subaCenter = (lat: 4.7410, lng: -74.0721)
    static let nearEquator = (lat: 0.5, lng: 0.5)
    static let southernHemisphere = (lat: -34.6037, lng: -58.3816)
    static let easternHemisphere = (lat: 40.4168, lng: -3.7038)
    
    static func runAllTests() {
        print("\n🧪 GeoCellService Test Vectors\n")
        
        print("--- Test 1: Suba Center (Bogotá) ---")
        GeoCellService.debugPrint(lat: subaCenter.lat, lng: subaCenter.lng)
        
        print("\n--- Test 2: Near Equator ---")
        GeoCellService.debugPrint(lat: nearEquator.lat, lng: nearEquator.lng)
        
        print("\n--- Test 3: Southern Hemisphere (Buenos Aires) ---")
        GeoCellService.debugPrint(lat: southernHemisphere.lat, lng: southernHemisphere.lng)
        
        print("\n--- Test 4: Eastern Hemisphere (Madrid) ---")
        GeoCellService.debugPrint(lat: easternHemisphere.lat, lng: easternHemisphere.lng)
        
        print("\n✅ Test vectors completed. Compare with Flutter output.\n")
    }
}
