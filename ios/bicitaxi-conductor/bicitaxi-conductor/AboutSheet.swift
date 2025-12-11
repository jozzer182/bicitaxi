//
//  AboutSheet.swift
//  bicitaxi-conductor
//
//  About the app modal - Light theme with app logo
//

import SwiftUI

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)
            
            // Content
            VStack(spacing: 28) {
                // App Logo from Assets (includes app name, no need to repeat)
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: BiciTaxiTheme.accentQuaternary.opacity(0.3), radius: 16, x: 0, y: 8)
                
                // Version
                Text("Versión 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Developer credit
                VStack(spacing: 12) {
                    Text("Desarrollado por")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("Jose Zarabanda")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(BiciTaxiTheme.accentGradient)
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 40)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Contact link
                Button {
                    if let url = URL(string: "https://zarabanda-dev.web.app") {
                        openURL(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                        Text("zarabanda-dev.web.app")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
                }
            }
            
            Spacer()
            
            // Footer
            Text("© 2025 Bici Taxi. Todos los derechos reservados.")
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.bottom, 16)
            
            // Close button at bottom
            Button {
                dismiss()
            } label: {
                Text("Cerrar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(BiciTaxiTheme.accentGradient)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    AboutSheet()
        .preferredColorScheme(.light)
}
