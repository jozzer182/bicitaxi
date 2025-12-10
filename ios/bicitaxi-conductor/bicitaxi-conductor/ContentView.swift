//
//  ContentView.swift
//  bicitaxi-conductor
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
                    .environment(\.authManager, authManager)
            }
        }
        .animation(.easeInOut, value: authManager.authState)
    }
}

// MARK: - Environment Key for AuthManager

private struct AuthManagerKey: EnvironmentKey {
    static let defaultValue: AuthManager? = nil
}

extension EnvironmentValues {
    var authManager: AuthManager? {
        get { self[AuthManagerKey.self] }
        set { self[AuthManagerKey.self] = newValue }
    }
}

#Preview {
    ContentView()
}

