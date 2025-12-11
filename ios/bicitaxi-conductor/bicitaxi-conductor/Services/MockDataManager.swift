//
//  MockDataManager.swift
//  bicitaxi-conductor
//
//  Manages the state of mockup data for development and testing.
//  When Firebase integration is complete, disable this to use real data.
//

import SwiftUI
import Foundation
import Combine

/// Manages mockup data state across the app
/// This allows toggling between demo data and blank/real data
class MockDataManager: ObservableObject {
    
    /// Shared instance for global access
    static let shared = MockDataManager()
    
    /// Key for UserDefaults storage
    private let mockDataEnabledKey = "mockDataEnabled"
    
    /// Whether mock data is enabled (defaults to true for development)
    @Published var isMockDataEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMockDataEnabled, forKey: mockDataEnabledKey)
        }
    }
    
    // MARK: - Demo Data
    
    /// Demo driver name (blank when mockup is disabled)
    var userName: String {
        isMockDataEnabled ? "Conductor Demo" : ""
    }
    
    /// Demo driver handle/ID (blank when mockup is disabled)
    var userHandle: String {
        isMockDataEnabled ? "conductor-demo" : ""
    }
    
    /// Demo driver email (blank when mockup is disabled)
    var userEmail: String {
        isMockDataEnabled ? "conductor@demo.com" : ""
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load saved state, default to true (mock data enabled)
        self.isMockDataEnabled = UserDefaults.standard.object(forKey: mockDataEnabledKey) as? Bool ?? true
    }
    
    // MARK: - Methods
    
    /// Toggle mock data state
    func toggleMockData() {
        isMockDataEnabled.toggle()
    }
    
    /// Reset to default (mock data enabled)
    func resetToDefault() {
        isMockDataEnabled = true
    }
}
