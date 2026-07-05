//
//  DesignSystem.swift
//  PrensaIA
//
//  Identidad visual: color de marca, Liquid Glass, tarjetas y botones.
//

import SwiftUI

// MARK: - Sistema de diseño

extension ShapeStyle where Self == Color {
    static var brand: Color { Color(red: 0.357, green: 0.310, blue: 0.878) }   // índigo editorial
}

extension LinearGradient {
    /// Degradado de marca (índigo → violeta profundo). Da vida a botones, ícono y acentos.
    static var brand: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.455, green: 0.375, blue: 0.965),
                     Color(red: 0.298, green: 0.231, blue: 0.843)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// Fondo con atmósfera: lavado de color de marca que hace brillar el cristal.
struct AppBackdrop: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            LinearGradient(
                colors: [Color.brand.opacity(0.16), Color.brand.opacity(0.05), .clear],
                startPoint: .top, endPoint: .center)
        }
        .ignoresSafeArea()
    }
}

extension View {
    // Tarjeta de material esmerilado: deja pasar el color del fondo (base del look iOS 26).
    func card() -> some View {
        self
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial,
                        in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 20, y: 12)
    }
}

extension View {
    /// Etiqueta de botón principal/secundario a lo ancho de la tarjeta.
    /// Se usa junto con los estilos NATIVOS de Liquid Glass de iOS 26:
    ///   .buttonStyle(.glassProminent)  → acción principal (vidrio entintado)
    ///   .buttonStyle(.glass)           → acciones secundarias (vidrio claro)
    /// Así el vidrio, el brillo y la reacción al toque los dibuja el sistema.
    func mainButtonLabel() -> some View {
        self
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }
}
