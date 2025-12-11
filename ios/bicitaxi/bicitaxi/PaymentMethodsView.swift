//
//  PaymentMethodsView.swift
//  bicitaxi
//
//  Payment methods selection view - Light theme
//

import SwiftUI

struct PaymentMethodsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMethod = "efectivo"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(BiciTaxiTheme.accentGradient)
                        
                        Text("Métodos de Pago")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 24)
                    
                    // Payment methods list
                    VStack(spacing: 12) {
                        // Cash - enabled and selected by default
                        paymentMethodRow(
                            icon: "banknote.fill",
                            title: "Efectivo",
                            id: "efectivo",
                            isEnabled: true
                        )
                        
                        // Other methods - disabled
                        paymentMethodRow(
                            icon: "creditcard.fill",
                            title: "Tarjeta Débito/Crédito",
                            id: "tarjeta",
                            isEnabled: false
                        )
                        
                        paymentMethodRow(
                            icon: "n.circle.fill",
                            title: "Nequi",
                            id: "nequi",
                            isEnabled: false
                        )
                        
                        paymentMethodRow(
                            icon: "d.circle.fill",
                            title: "Daviplata",
                            id: "daviplata",
                            isEnabled: false
                        )
                        
                        paymentMethodRow(
                            icon: "b.circle.fill",
                            title: "Bancolombia",
                            id: "bancolombia",
                            isEnabled: false
                        )
                        
                        paymentMethodRow(
                            icon: "key.fill",
                            title: "Llave",
                            id: "llave",
                            isEnabled: false
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Info message
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(BiciTaxiTheme.accentGradient)
                        
                        Text("Pronto estarán disponibles más métodos de pago. Por ahora solo puedes pagar en efectivo.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .background(BiciTaxiTheme.accentPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 50)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(BiciTaxiTheme.accentGradient)
                }
            }
        }
    }
    
    private func paymentMethodRow(icon: String, title: String, id: String, isEnabled: Bool) -> some View {
        Button {
            if isEnabled {
                selectedMethod = id
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isEnabled ? AnyShapeStyle(BiciTaxiTheme.accentGradient) : AnyShapeStyle(Color.gray.opacity(0.4)))
                    .frame(width: 30)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isEnabled ? .black : .gray)
                
                Spacer()
                
                if isEnabled {
                    Image(systemName: selectedMethod == id ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedMethod == id ? AnyShapeStyle(BiciTaxiTheme.accentGradient) : AnyShapeStyle(Color.gray.opacity(0.3)))
                        .font(.title3)
                } else {
                    Text("Próximamente")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.5))
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(isEnabled ? Color.gray.opacity(0.08) : Color.gray.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    PaymentMethodsView()
        .preferredColorScheme(.light)
}
