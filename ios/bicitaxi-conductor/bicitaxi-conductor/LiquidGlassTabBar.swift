//
//  LiquidGlassTabBar.swift
//  bicitaxi-conductor
//
//  iOS 26 Native Liquid Glass Tab Bar - Apple News style
//  - LEGIBLE with solid frosted background
//  - Transient water drop (only during transitions)
//  - Pill-like rounded shape extending above bar
//  - Scale-down then fade-out animation
//

import SwiftUI

/// iOS 26 Liquid Glass Tab Bar - Apple News style
struct LiquidGlassTabBar: View {
    
    // MARK: - State
    
    @Binding var selectedTab: AppTab
    @State private var isTransitioning: Bool = false
    @State private var showDrop: Bool = false
    @State private var dropScale: CGFloat = 1.0
    @State private var dropPosition: CGFloat = 0
    
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Dimensions
    
    private let barHeight: CGFloat = 54
    private let iconSize: CGFloat = 22
    
    // Drop dimensions - pill-like shape that extends above bar
    private let dropHeight: CGFloat = 58
    private let dropOffset: CGFloat = -4
    
    // MARK: - Colors
    
    private var barBackground: Color {
        colorScheme == .dark 
            ? Color.black.opacity(0.6)
            : Color.white.opacity(0.85)
    }
    
    private var dropColor: Color {
        colorScheme == .dark 
            ? Color.white.opacity(0.15)
            : Color.white.opacity(0.95)
    }
    
    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.25)
            : Color.black.opacity(0.08)
    }
    
    private var unselectedColor: Color {
        colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5)
    }
    
    private var selectedColor: Color {
        BiciTaxiTheme.accentPrimary
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let tabWidth = geometry.size.width / CGFloat(AppTab.allCases.count)
            let dropWidth = tabWidth * 0.95
            
            ZStack {
                // MARK: - Solid Frosted Background for Legibility
                Capsule()
                    .fill(barBackground)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                
                // MARK: - Glass Effect Overlay
                GlassEffectContainer {
                    Capsule()
                        .fill(.clear)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
                
                // MARK: - Tab Buttons
                HStack(spacing: 0) {
                    ForEach(AppTab.allCases) { tab in
                        tabButton(for: tab, tabWidth: tabWidth)
                    }
                }
                
                // MARK: - Transient Water Drop (only during transitions)
                if showDrop {
                    waterDrop(dropWidth: dropWidth)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                        .allowsHitTesting(false)
                }
            }
            .frame(height: barHeight)
            .onAppear {
                dropPosition = CGFloat(selectedTab.rawValue)
            }
        }
        .frame(height: barHeight + 14)
    }
    
    // MARK: - Water Drop (Transient) - REAL iOS 26 Liquid Glass
    
    private func waterDrop(dropWidth: CGFloat) -> some View {
        GeometryReader { geometry in
            let tabWidth = geometry.size.width / CGFloat(AppTab.allCases.count)
            let xPosition = (dropPosition + 0.5) * tabWidth
            let cornerRadius: CGFloat = 24
            
            // REAL iOS 26 Liquid Glass - .clear variant = most transparent, minimal blur
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.clear)
                .glassEffect(
                    .clear.interactive(),  // .clear = transparent glass, less blur than .regular
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .frame(width: dropWidth, height: dropHeight)
                .scaleEffect(dropScale)
                .position(x: xPosition, y: barHeight / 2 + dropOffset)
        }
    }
    
    // MARK: - Tab Button
    
    private func tabButton(for tab: AppTab, tabWidth: CGFloat) -> some View {
        let isSelected = selectedTab == tab
        
        return Button {
            guard tab != selectedTab else { return }
            
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            isTransitioning = true
            
            // 1. FIRST: Show drop at ORIGIN (current position) with scale-up
            dropScale = 0.5  // Start small
            showDrop = true
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                dropScale = 1.0  // Scale up at origin
            }
            
            // 2. THEN: Travel to destination after brief pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    dropPosition = CGFloat(tab.rawValue)
                    selectedTab = tab
                }
            }
            
            // 3. Scale down at destination
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeOut(duration: 0.25)) {
                    dropScale = 0.85
                }
            }
            
            // 4. Fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showDrop = false
                }
                isTransitioning = false
            }
            
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: iconSize, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(BiciTaxiTheme.accentGradient)
                            : AnyShapeStyle(unselectedColor)
                    )
                
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? selectedColor : unselectedColor)
            }
            .frame(width: tabWidth, height: barHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityHint(tab.accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack {
            Spacer()
            LiquidGlassTabBar(selectedTab: .constant(.map))
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
    }
}
