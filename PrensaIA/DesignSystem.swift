//
//  DesignSystem.swift
//  PrensaIA
//
//  Identidad visual PL: vino/granate + cápsulas doradas + serif editorial,
//  sobre el lenguaje Liquid Glass nativo de iOS 26.
//
//  Los colores viven en Assets.xcassets como colores ADAPTATIVOS (claro/oscuro):
//  aquí solo se exponen con nombres cómodos. El vidrio lo dibuja el sistema
//  (.glassEffect / .buttonStyle(.glass)); las cápsulas doradas y vino son
//  SÓLIDAS a propósito — son la firma de la marca, nunca vidrio.
//

import SwiftUI
import CoreText

// MARK: - Colores de marca (tokens)

extension ShapeStyle where Self == Color {
    /// Vino PL — tinte de botones prominentes, thumb del segmentado, toggles.
    static var brand: Color { Color("BrandPrimary") }
    /// Vino/rosa legible — íconos, links y acentos SOBRE el fondo.
    static var brandText: Color { Color("BrandText") }
    /// Fondo base de toda la app.
    static var baseBackground: Color { Color("BaseBackground") }
    static var textPrimary: Color { Color("TextPrimary") }
    static var textSecondary: Color { Color("TextSecondary") }
    static var textTertiary: Color { Color("TextTertiary") }
    /// Oro de las cápsulas (mismo en claro y oscuro).
    static var goldFill: Color { Color("AccentGoldFill") }
    /// Texto dentro de cápsulas doradas.
    static var onGold: Color { Color("OnGold") }
    /// Eyebrows y labels dorados sobre el fondo.
    static var goldText: Color { Color("GoldText") }
    /// Fondos suaves (fila activa, tracks).
    static var brandSoft: Color { Color("BrandSoft") }
    /// Separadores hairline.
    static var hairline: Color { Color("HairlineDivider") }
    /// Punto REC, Detener, acciones destructivas.
    static var liveRed: Color { Color("LiveRed") }
    static var successGreen: Color { Color("SuccessGreen") }
}

extension Color {
    /// Colores de orador (rotación por id % 7), adaptativos claro/oscuro.
    static func speaker(_ id: Int, dark: Bool) -> Color {
        let light: [UInt32] = [0x611029, 0x8E6D25, 0xB02A5B, 0x3A6B5A, 0x3D5A80, 0x8A5A2B, 0x6B4B7A]
        let darkP: [UInt32] = [0xE79BB7, 0xD9B565, 0xE2638F, 0x7FBFA5, 0x8FB4DC, 0xD2A06B, 0xB99BC8]
        let hex = (dark ? darkP : light)[((id % 7) + 7) % 7]
        return Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension LinearGradient {
    /// Degradado de marca (magenta → vino profundo). Acentos y anillos.
    static var brand: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.690, green: 0.165, blue: 0.357),
                     Color(red: 0.380, green: 0.063, blue: 0.161)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Tipografía de marca

/// Fuentes de la identidad PL: Montserrat (display) y Playfair Display Italic
/// (serif editorial). Vienen empaquetadas como fuentes VARIABLES y se registran
/// al arrancar. Si algo fallara, caemos a SF Pro / New York sin romper nada.
enum PLFonts {
    private static var registered = false
    /// true si Montserrat quedó disponible tras registrar.
    private(set) static var hasDisplay = false
    /// true si Playfair quedó disponible tras registrar.
    private(set) static var hasSerif = false

    static func registerAll() {
        guard !registered else { return }
        registered = true
        for name in ["Montserrat", "PlayfairDisplay-Italic"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        hasDisplay = UIFont(name: "Montserrat-Bold", size: 12) != nil
        hasSerif = UIFont(name: "PlayfairDisplay-BoldItalic", size: 12) != nil
    }
}

extension Font {
    /// Display de marca (Montserrat). Pesos del prototipo: 500–900.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        PLFonts.registerAll()
        guard PLFonts.hasDisplay else { return .system(size: size, weight: weight) }
        let name: String
        switch weight {
        case .black: name = "Montserrat-Black"
        case .heavy: name = "Montserrat-ExtraBold"
        case .bold: name = "Montserrat-Bold"
        case .semibold: name = "Montserrat-SemiBold"
        default: name = "Montserrat-Medium"
        }
        return .custom(name, size: size)
    }

    /// Serif editorial en itálica (Playfair Display) — citas, fechas,
    /// estenográfica, titulares de resultados.
    static func serifItalic(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        PLFonts.registerAll()
        guard PLFonts.hasSerif else {
            return .system(size: size, weight: weight, design: .serif).italic()
        }
        let name: String
        switch weight {
        case .black, .heavy: name = "PlayfairDisplay-ExtraBoldItalic"
        case .bold: name = "PlayfairDisplay-BoldItalic"
        case .semibold: name = "PlayfairDisplay-SemiBoldItalic"
        default: name = "PlayfairDisplay-Italic"
        }
        return .custom(name, size: size)
    }
}

// MARK: - Fondo ambiental (firma visual)

// BaseBackground + 3 radiales muy suaves (oro, magenta, vino). Los blobs de
// color son lo que el vidrio refracta: sin ellos, el glass parece pintura.
// Estático a propósito (sin animación) y aplanado a una sola capa de GPU.
struct AppBackdrop: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Color.baseBackground
                if scheme == .dark {
                    blob(Color(red: 0.690, green: 0.165, blue: 0.357).opacity(0.42),
                         w: w * 0.92, h: h * 0.64, x: w * 0.14, y: h * 0.02)
                    blob(Color(red: 0.796, green: 0.627, blue: 0.290).opacity(0.15),
                         w: w * 0.80, h: h * 0.56, x: w * 0.94, y: h * 0.12)
                    blob(Color(red: 0.471, green: 0.086, blue: 0.204).opacity(0.58),
                         w: w * 1.68, h: h * 1.04, x: w * 0.50, y: h * 1.14)
                } else {
                    blob(Color(red: 0.796, green: 0.627, blue: 0.290).opacity(0.34),
                         w: w * 0.84, h: h * 0.60, x: w * 0.12, y: h * 0.04)
                    blob(Color(red: 0.690, green: 0.165, blue: 0.357).opacity(0.20),
                         w: w * 1.00, h: h * 0.68, x: w * 0.98, y: h * 0.18)
                    blob(Color(red: 0.380, green: 0.063, blue: 0.161).opacity(0.28),
                         w: w * 1.44, h: h * 0.92, x: w * 0.50, y: h * 1.10)
                }
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
    }

    private func blob(_ color: Color, w: CGFloat, h: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Ellipse()
            .fill(RadialGradient(colors: [color, color.opacity(0)],
                                 center: .center,
                                 startRadius: 0,
                                 endRadius: max(w, h) / 2))
            .frame(width: w, height: h)
            .position(x: x, y: y)
    }
}

// MARK: - Tarjetas de vidrio

extension View {
    /// Tarjeta de material esmerilado (radio 26) con sombra de marca.
    func card() -> some View {
        modifier(PLCardModifier(radius: 26, padding: 20))
    }

    /// Variante con radio/padding a la medida (tiles, paneles chicos).
    func card(radius: CGFloat, padding: CGFloat = 16) -> some View {
        modifier(PLCardModifier(radius: radius, padding: padding))
    }
}

private struct PLCardModifier: ViewModifier {
    let radius: CGFloat
    let padding: CGFloat
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial,
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: scheme == .dark ? .black.opacity(0.55)
                                           : Color(red: 0.310, green: 0.039, blue: 0.129).opacity(0.14),
                    radius: scheme == .dark ? 22 : 16,
                    y: scheme == .dark ? 16 : 12)
    }
}

// MARK: - Piezas de identidad PL

/// Cápsula SÓLIDA (nunca vidrio) — la firma PL.
/// Dorada: "IA LOCAL", badge "IA". Vino: "EN VIVO", badge "MÍO".
struct PLCapsule: View {
    enum Variant { case gold, wine }
    let text: String
    var variant: Variant = .gold
    var size: CGFloat = 11

    var body: some View {
        Text(text)
            .font(.display(size, .heavy))
            .tracking(0.5)
            .lineLimit(1)
            .foregroundStyle(variant == .gold ? Color.onGold : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 3.5)
            .background(variant == .gold ? Color.goldFill : Color.brand, in: Capsule())
            .shadow(color: Color(red: 0.310, green: 0.039, blue: 0.129).opacity(0.18),
                    radius: 4, y: 2)
    }
}

/// Eyebrow dorado en mayúsculas con ícono (encabezados editoriales).
struct PLEyebrow: View {
    let icon: String?
    let text: String
    var color: Color = .goldText

    init(_ text: String, icon: String? = nil, color: Color = .goldText) {
        self.text = text
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(spacing: 7) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
            }
            Text(text.uppercased())
                .font(.display(11, .heavy))
                .tracking(1.4)
        }
        .foregroundStyle(color)
    }
}

/// Label de sección en mayúsculas (TextTertiary).
struct PLSectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.display(11.5, .bold))
            .tracking(1.0)
            .foregroundStyle(.textTertiary)
            .padding(.horizontal, 10)
            .padding(.bottom, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    /// Etiqueta de botón principal/secundario a lo ancho de la tarjeta.
    /// Se usa junto con los estilos NATIVOS de Liquid Glass de iOS 26:
    ///   .buttonStyle(.glassProminent)  → acción principal (vidrio entintado)
    ///   .buttonStyle(.glass)           → acciones secundarias (vidrio claro)
    func mainButtonLabel() -> some View {
        self
            .font(.display(15.5, .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
    }
}
