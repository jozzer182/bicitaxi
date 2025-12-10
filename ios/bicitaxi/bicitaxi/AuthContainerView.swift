//
//  AuthContainerView.swift
//  bicitaxi
//
//  Container view for authentication flow
//

import SwiftUI

/// Container view that manages navigation between Login and Register
struct AuthContainerView: View {
    @ObservedObject var authManager: AuthManager
    @State private var showRegister = false
    
    var body: some View {
        ZStack {
            // Background
            BiciTaxiTheme.background
                .ignoresSafeArea()
            
            // Animated gradient background
            backgroundGradient
            
            // Content
            if showRegister {
                RegisterView(authManager: authManager, showRegister: $showRegister)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            } else {
                LoginView(authManager: authManager, showRegister: $showRegister)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showRegister)
    }
    
    // MARK: - Background Gradient
    
    private var backgroundGradient: some View {
        ZStack {
            // Top accent glow
            Circle()
                .fill(BiciTaxiTheme.accentPrimary)
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .opacity(0.2)
                .offset(x: 100, y: -200)
            
            // Bottom accent glow
            Circle()
                .fill(BiciTaxiTheme.accentTertiary)
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .opacity(0.15)
                .offset(x: -100, y: 300)
        }
    }
}

#Preview {
    AuthContainerView(authManager: AuthManager())
        .preferredColorScheme(.dark)
}
