import SwiftUI

/// Página 2: las cuatro barras de estado de la mascota.
struct StatsView: View {
    let pet: Pet

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 10) {
                StatBar(label: "Hambre",  systemImage: "fork.knife",   value: pet.hunger,    color: .orange)
                StatBar(label: "Ánimo",   systemImage: "face.smiling", value: pet.happiness, color: .yellow)
                StatBar(label: "Energía", systemImage: "bolt.fill",    value: pet.energy,    color: .green)
                StatBar(label: "Higiene", systemImage: "drop.fill",    value: pet.hygiene,   color: .cyan)
            }
            .padding()
        }
    }
}

/// Una barra horizontal con icono, color propio y relleno animado.
/// Se pone roja cuando el valor cae por debajo del umbral bajo.
private struct StatBar: View {
    let label: String
    let systemImage: String
    let value: Double
    let color: Color

    private var isLow: Bool { value < Balance.lowThreshold }
    private var fillColor: Color { isLow ? .red : color }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.footnote)
                .foregroundStyle(fillColor)
                .frame(width: 18)

            GeometryReader { geo in
                let fraction = value / Balance.statRange.upperBound
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.15))
                    Capsule()
                        .fill(fillColor)
                        .frame(width: max(0, geo.size.width * fraction))
                }
            }
            .frame(height: 10)
            .animation(.easeInOut(duration: 0.35), value: value)
        }
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue("\(Int(value))")
    }
}
