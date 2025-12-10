//
//  BiciTaxiTheme.swift
//  bicitaxi
//
//  iOS 26 Native Liquid Glass Design System
//

import SwiftUI

/// Bici Taxi Design System with iOS 26 Native Liquid Glass
struct BiciTaxiTheme {
    
    // MARK: - Colors
    
    /// Primary dark background color (#0B0016)
    static let background = Color(red: 0.043, green: 0, blue: 0.086)
    
    /// Primary accent blue (#4BB3FD)
    static let accentPrimary = Color(red: 0.294, green: 0.702, blue: 0.992)
    
    /// Secondary accent (#3E6680)
    static let accentSecondary = Color(red: 0.243, green: 0.4, blue: 0.502)
    
    /// Tertiary accent (#0496FF)
    static let accentTertiary = Color(red: 0.016, green: 0.588, blue: 1.0)
    
    /// Quaternary accent (#027BCE)
    static let accentQuaternary = Color(red: 0.008, green: 0.482, blue: 0.808)
    
    // MARK: - Map Marker Colors
    
    /// Pickup point color - uses light blue for visibility
    static let pickupColor = accentPrimary
    
    /// Destination point color - uses deeper blue for contrast
    static let destinationColor = accentQuaternary
    
    /// Route gradient from pickup to destination
    static let routeGradient = LinearGradient(
        colors: [pickupColor, destinationColor],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Gradient for accent elements
    static let accentGradient = LinearGradient(
        colors: [accentPrimary, accentTertiary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Currency Formatting
    
    /// Format amount as Colombian Pesos (no cents, dot as thousands separator)
    /// Example: 15000 -> "$15.000"
    static func formatCOP(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        return "$" + (formatter.string(from: NSNumber(value: amount)) ?? "\(amount)")
    }
    
    // MARK: - Dimensions
    
    /// Standard corner radius for glass cards
    static let cornerRadius: CGFloat = 24
    
    /// Standard padding
    static let padding: CGFloat = 16
    
    /// Maximum content width for iPad responsiveness
    static let maxContentWidth: CGFloat = 600
}

// MARK: - iOS 26 Native Glass Modifiers

/// Modifier for applying native glass card styling
struct NativeGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = BiciTaxiTheme.cornerRadius
    
    func body(content: Content) -> some View {
        content
            .glassEffect(in: .rect(cornerRadius: cornerRadius))
    }
}

/// Modifier for applying the liquid glass background
struct LiquidGlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(BiciTaxiTheme.background)
    }
}

/// Modifier for responsive container that works on iPhone and iPad
struct ResponsiveContainer: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let isCompact = horizontalSizeClass == .compact
            let maxWidth = isCompact ? geometry.size.width : min(geometry.size.width * 0.8, BiciTaxiTheme.maxContentWidth)
            
            HStack {
                Spacer()
                content
                    .frame(maxWidth: maxWidth)
                Spacer()
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply native iOS 26 glass card styling
    func glassCard(cornerRadius: CGFloat = BiciTaxiTheme.cornerRadius) -> some View {
        modifier(NativeGlassCardModifier(cornerRadius: cornerRadius))
    }
    
    /// Apply the liquid glass background to a view
    func liquidGlassBackground() -> some View {
        modifier(LiquidGlassBackground())
    }
    
    /// Make the view responsive for iPhone and iPad
    func responsiveContainer() -> some View {
        modifier(ResponsiveContainer())
    }
}
