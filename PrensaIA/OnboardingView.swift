//
//  OnboardingView.swift
//  PrensaIA
//
//  Bienvenida que se muestra solo la primera vez.
//

import SwiftUI

// MARK: - Bienvenida (solo la primera vez)

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var page = 0

    private struct Feature {
        let icon: String
        let title: String
        let text: String
    }

    private let features: [Feature] = [
        Feature(icon: "waveform",
                title: "Transcribe sin internet",
                text: "Sube un archivo, graba o captura audio. Todo se procesa dentro de tu iPhone: rápido, privado y sin depender de la señal."),
        Feature(icon: "dot.radiowaves.left.and.right",
                title: "Facebook Live, sin bocina",
                text: "Captura el audio de una transmisión directamente del teléfono y léela casi en tiempo real. Nadie a tu alrededor escucha nada."),
        Feature(icon: "scissors",
                title: "Tus temas y tus cortes",
                text: "Marca los momentos importantes con tu nombre de tema, deja que la IA sugiera bloques, y exporta clips de video listos para publicar."),
        Feature(icon: "sparkles",
                title: "Análisis periodístico",
                text: "Resumen, temas, citas textuales verificadas y titulares sugeridos. Y si tienes dudas, pregúntale directamente a la entrevista.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Saltar") { isPresented = false }
                    .font(.display(14, .semibold))
                    .foregroundStyle(.textTertiary)
                    .padding(.trailing, 20)
                    .padding(.top, 18)
            }

            TabView(selection: $page) {
                ForEach(Array(features.enumerated()), id: \.offset) { i, f in
                    VStack(spacing: 28) {
                        Circle()
                            .fill(LinearGradient.brand)
                            .frame(width: 104, height: 104)
                            .overlay {
                                Image(systemName: f.icon)
                                    .font(.system(size: 46, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: .brand.opacity(0.4), radius: 18, y: 10)

                        VStack(spacing: 13) {
                            Text(f.title)
                                .font(.serifItalic(27, .heavy))
                                .foregroundStyle(.textPrimary)
                                .multilineTextAlignment(.center)
                            Text(f.text)
                                .font(.display(14.5, .medium))
                                .foregroundStyle(.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(8)
                                .frame(maxWidth: 300)
                        }
                    }
                    .tag(i)
                    .padding(.bottom, 46)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Dots de página (8pt, activo vino).
            HStack(spacing: 8) {
                ForEach(features.indices, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Color.brand : Color.hairline)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 22)
            .animation(.smooth(duration: 0.25), value: page)

            Button {
                if page < features.count - 1 {
                    withAnimation(.smooth(duration: 0.3)) { page += 1 }
                } else {
                    isPresented = false
                }
            } label: {
                Text(page < features.count - 1 ? "Siguiente" : "Comenzar")
                    .mainButtonLabel()
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.roundedRectangle(radius: 18))
            .tint(.brand)
            .padding(.horizontal, 26)
            .padding(.bottom, 26)
        }
        .background { AppBackdrop() }
        .interactiveDismissDisabled(false)
    }
}
