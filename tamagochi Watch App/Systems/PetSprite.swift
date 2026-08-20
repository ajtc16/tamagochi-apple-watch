import SwiftUI
import UIKit

/// Dibuja un sprite del juego a partir del nombre de un asset.
///
/// Si el asset existe en el catálogo se usa la imagen real (pixel-art, sin
/// interpolación). Si todavía no existe, cae automáticamente en un SF Symbol
/// equivalente definido en `fallbackTable`. Así la app se ve bien hoy y adopta
/// las imágenes reales en cuanto se añaden al catálogo, sin tocar código.
struct PetSprite: View {
    let assetName: String

    var body: some View {
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
        } else {
            Image(systemName: Self.fallbackSymbol(for: assetName))
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.hierarchical)
        }
    }

    /// SF Symbol equivalente para un asset que aún no está en el catálogo.
    static func fallbackSymbol(for assetName: String) -> String {
        fallbackTable[assetName] ?? "questionmark.square.dashed"
    }

    /// Tabla de fallback: nombre de asset → SF Symbol.
    /// Cubre los sprites de mascota (`pet_*`) y los iconos de objetos (`item_*`).
    static let fallbackTable: [String: String] = {
        // Símbolo por estado de ánimo, común a todas las etapas con mood.
        let moodSymbols: [String: String] = [
            "idle":     "face.smiling",
            "happy":    "face.smiling.inverse",
            "eating":   "fork.knife",
            "sleeping": "moon.zzz.fill",
            "sad":      "cloud.rain.fill",
            "sick":     "thermometer.medium",
        ]

        var table: [String: String] = [
            // Huevo y fantasma
            "pet_egg_idle":    "oval.portrait.fill",
            "pet_egg_cracked": "burst.fill",
            "pet_ghost":       "smoke.fill",

            // Iconos de objetos
            "item_food_fruit": "carrot.fill",
            "item_food_meal":  "fork.knife.circle.fill",
            "item_soap":       "bubbles.and.sparkles.fill",
            "item_ball":       "soccerball",
            "item_medicine":   "pills.fill",
            "item_poop":       "aqi.medium",
        ]

        // Sprites de mascota con mood: baby / child / adult × moods.
        for stage in ["baby", "child", "adult"] {
            for (mood, symbol) in moodSymbols {
                table["pet_\(stage)_\(mood)"] = symbol
            }
        }

        return table
    }()
}
