//
//  ContentView.swift
//  bicitaxi
//
//  Created by JOSE ZARABANDA on 12/9/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .unauthenticated:
                AuthContainerView(authManager: authManager)
            case .guest, .authenticated:
                MainTabView()
                    .environmentObject(authManager)
            }
        }
        .animation(.easeInOut, value: authManager.authState)
    }
}

#Preview {
    ContentView()
}

