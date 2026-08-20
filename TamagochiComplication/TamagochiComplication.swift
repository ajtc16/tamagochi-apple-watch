import WidgetKit
import SwiftUI

// MARK: - Timeline entry

struct PetEntry: TimelineEntry {
    let date: Date
    let pet: Pet?
}

// MARK: - Provider

struct PetProvider: TimelineProvider {
    /// Cada cuánto se genera una entrada y durante cuánto tiempo.
    private static let step: TimeInterval = 15 * 60          // 15 minutos
    private static let horizon: TimeInterval = 4 * 60 * 60   // 4 horas

    func placeholder(in context: Context) -> PetEntry {
        PetEntry(date: .now, pet: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> Void) {
        completion(PetEntry(date: .now, pet: SharedStorage.loadPet()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> Void) {
        let base = SharedStorage.loadPet()
        let now = Date.now
        let count = Int(Self.horizon / Self.step)

        var entries: [PetEntry] = []
        for i in 0...count {
            let date = now.addingTimeInterval(Self.step * Double(i))
            // Estado futuro proyectado, SIN guardarlo.
            var future = base
            future?.advance(to: date)
            entries.append(PetEntry(date: date, pet: future))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Vistas

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PetEntry

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryCorner:   corner
        case .accessoryInline:   inline
        default:                 inline
        }
    }

    // Circular: sprite pequeño con anillo del stat más bajo.
    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let pet = entry.pet {
                let low = Self.lowestStat(pet)
                Circle()
                    .stroke(.gray.opacity(0.3), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: low.value / Balance.statRange.upperBound)
                    .stroke(Self.ringColor(low.value),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                PetSprite(assetName: pet.spriteName)
                    .padding(9)
            } else {
                Image(systemName: "oval.portrait.fill")
                    .padding(10)
            }
        }
    }

    // Corner: sprite en la esquina con etiqueta curva de gauge.
    private var corner: some View {
        PetSprite(assetName: entry.pet?.spriteName ?? "pet_egg_idle")
            .widgetLabel {
                if let pet = entry.pet {
                    let low = Self.lowestStat(pet)
                    Gauge(value: low.value, in: 0...Balance.statRange.upperBound) {
                        Text(low.label)
                    }
                    .tint(Self.ringColor(low.value))
                }
            }
    }

    // Inline: "🥚 Hambre 40%".
    private var inline: some View {
        Group {
            if let pet = entry.pet {
                let low = Self.lowestStat(pet)
                Text("\(Self.stageEmoji(pet)) \(low.label) \(Int(low.value))%")
            } else {
                Text("🥚 Tamagochi")
            }
        }
    }

    // MARK: - Helpers

    private static func lowestStat(_ pet: Pet) -> (label: String, value: Double) {
        let stats: [(String, Double)] = [
            ("Hambre", pet.hunger),
            ("Ánimo", pet.happiness),
            ("Energía", pet.energy),
            ("Higiene", pet.hygiene),
        ]
        let lowest = stats.min { $0.1 < $1.1 } ?? ("Hambre", pet.hunger)
        return (lowest.0, lowest.1)
    }

    private static func ringColor(_ value: Double) -> Color {
        value < Balance.lowThreshold ? .red : .green
    }

    private static func stageEmoji(_ pet: Pet) -> String {
        switch pet.stage {
        case .egg:   return "🥚"
        case .baby:  return "🐣"
        case .child: return "🐤"
        case .adult: return "🐔"
        case .ghost: return "👻"
        }
    }
}

// MARK: - Widget

struct TamagochiComplicationWidget: Widget {
    let kind = "TamagochiComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetProvider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("Tamagochi")
        .description("El estado de tu mascota de un vistazo.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

@main
struct TamagochiComplicationBundle: WidgetBundle {
    var body: some Widget {
        TamagochiComplicationWidget()
    }
}
