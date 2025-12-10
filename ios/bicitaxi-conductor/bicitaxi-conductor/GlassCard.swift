//
//  GlassCard.swift
//  bicitaxi-conductor
//
//  Reusable Glass Card Component
//

import SwiftUI

/// A reusable glass card component with blur effect and rounded corners
struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat
    var padding: CGFloat
    
    init(
        cornerRadius: CGFloat = BiciTaxiTheme.cornerRadius,
        padding: CGFloat = BiciTaxiTheme.padding,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .glassCard(cornerRadius: cornerRadius)
    }
}

/// A simple placeholder view for tabs
struct PlaceholderTabView: View {
    let title: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            GlassCard {
                VStack(spacing: 16) {
                    Image(systemName: systemImage)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(BiciTaxiTheme.accentGradient)
                    
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Coming soon")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
            .padding(.horizontal, BiciTaxiTheme.padding)
            
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        BiciTaxiTheme.background.ignoresSafeArea()
        
        PlaceholderTabView(title: "Home", systemImage: "house.fill")
    }
    .preferredColorScheme(.dark)
}
