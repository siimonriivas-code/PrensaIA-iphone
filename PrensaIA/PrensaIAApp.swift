//
//  PrensaIAApp.swift
//  PrensaIA
//
//  Created by CIAPA on 13/06/26.
//

import SwiftUI

@main
struct PrensaIAApp: App {
    // Tema elegido por el usuario (sistema / claro / oscuro).
    // Se aplica aquí, en la raíz, para que cubra TODA la app (incluidas las hojas).
    @AppStorage("prensaia_theme") private var themeRaw = "system"

    private var colorScheme: ColorScheme? {
        switch themeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
        }
    }
}
