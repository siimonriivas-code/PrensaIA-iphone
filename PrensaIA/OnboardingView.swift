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
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 20)
                    .padding(.top, 18)
            }

            TabView(selection: $page) {
                ForEach(Array(features.enumerated()), id: \.offset) { i, f in
                    VStack(spacing: 26) {
                        Circle()
                            .fill(LinearGradient.brand)
                            .frame(width: 96, height: 96)
                            .overlay {
                                Image(systemName: f.icon)
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: .brand.opacity(0.4), radius: 18, y: 10)

                        VStack(spacing: 12) {
                            Text(f.title)
                                .font(.system(.title, design: .serif, weight: .bold))
                                .multilineTextAlignment(.center)
                            Text(f.text)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 34)
                        }
                    }
                    .tag(i)
                    .padding(.bottom, 46)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < features.count - 1 {
                    withAnimation(.smooth(duration: 0.3)) { page += 1 }
                } else {
                    isPresented = false
                }
            } label: {
                Text(page < features.count - 1 ? "Siguiente" : "Comenzar")
                    .mainButtonLabel()
            }
            .buttonStyle(.glassProminent)
            .tint(.brand)
            .padding(.horizontal, 26)
            .padding(.bottom, 26)
        }
        .background { AppBackdrop() }
        .interactiveDismissDisabled(false)
    }
}
