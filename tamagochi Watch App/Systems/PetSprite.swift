import SwiftUI
import UIKit

/// Dibuja un sprite del juego a partir del nombre de un asset.
///
/// Resolución en cascada, de más a menos rico:
///   1. Frames animados: `nombre_0`, `nombre_1`, … → se ciclan con `TimelineView`.
///   2. Imagen única `nombre` → estática.
///   3. Nada en el catálogo → SF Symbol de `fallbackTable`.
///
/// Así la app se ve bien hoy (SF Symbols) y adopta el pixel-art —animado o no—
/// automáticamente en cuanto los assets están en el catálogo, sin tocar código.
struct PetSprite: View {
    let assetName: String
    /// Fotogramas por segundo de la animación.
    var fps: Double = 4

    var body: some View {
        let frames = Self.frames(for: assetName)
        if frames.count >= 2 {
            TimelineView(.periodic(from: .now, by: 1.0 / fps)) { context in
                let tick = Int(context.date.timeIntervalSinceReferenceDate * fps)
                image(frames[tick % frames.count])
            }
        } else if let single = frames.first {
            image(single)
        } else {
            fallbackImage
        }
    }

    private func image(_ name: String) -> some View {
        Image(name)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
    }

    private var fallbackImage: some View {
        Image(systemName: Self.fallbackSymbol(for: assetName))
            .resizable()
            .scaledToFit()
            .symbolRenderingMode(.hierarchical)
    }

    // MARK: - Descubrimiento de frames

    /// Cache de nombres de asset existentes por base (los assets no cambian en runtime).
    private static var frameCache: [String: [String]] = [:]

    /// Devuelve los nombres de asset a usar: `[base_0, base_1, …]`, o `[base]`,
    /// o `[]` si no hay ninguno en el catálogo.
    static func frames(for base: String) -> [String] {
        if let cached = frameCache[base] { return cached }

        var result: [String] = []
        var i = 0
        while UIImage(named: "\(base)_\(i)") != nil {
            result.append("\(base)_\(i)")
            i += 1
        }
        if result.isEmpty, UIImage(named: base) != nil {
            result = [base]
        }

        frameCache[base] = result
        return result
    }

    // MARK: - Fallback a SF Symbols

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
