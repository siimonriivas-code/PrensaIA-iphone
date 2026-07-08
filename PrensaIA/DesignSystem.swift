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

// Fondo "aurora": manchas de color difuminadas sobre el fondo del sistema.
// ESTO es lo que hace visible el Liquid Glass: el vidrio y los materiales
// refractan este color. Sin color detrás, el vidrio parece pintura plana.
//
// Rendimiento: usa `.drawingGroup()` para aplanar todo el aurora a UNA sola
// capa (imagen) en la GPU. Así el desenfoque se calcula una vez y el scroll
// queda fluido, en vez de recalcular 3 blur pesados en cada cuadro.
struct AppBackdrop: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            Circle()
                .fill(Color.brand.opacity(0.40))
                .frame(width: 420, height: 420)
                .blur(radius: 60)
                .offset(x: -130, y: -280)
            Circle()
                .fill(Color(red: 0.62, green: 0.32, blue: 0.95).opacity(0.32))
                .frame(width: 360, height: 360)
                .blur(radius: 65)
                .offset(x: 170, y: -60)
            Circle()
                .fill(Color(red: 0.20, green: 0.55, blue: 0.95).opacity(0.26))
                .frame(width: 400, height: 400)
                .blur(radius: 70)
                .offset(x: -40, y: 380)
        }
        .drawingGroup()
        .ignoresSafeArea()
    }
}

extension View {
    // Tarjeta de material esmerilado: deja pasar el color del fondo (base del look iOS 26).
    func card() -> some View {
        self
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial,
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
