//
//  MainTabView.swift
//  bicitaxi
//
//  Main tab container with Liquid Glass styling
//

import SwiftUI

/// Main tab container for the Bici Taxi client app
/// Uses custom Liquid Glass navigation with water-drop transitions
struct MainTabView: View {
    private let repo = InMemoryRideRepository()
    
    var body: some View {
        LiquidGlassTabShell(repo: repo)
    }
}

#Preview {
    MainTabView()
}
