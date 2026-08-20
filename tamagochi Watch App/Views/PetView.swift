import SwiftUI

/// Página 1: la mascota, su animación de respiración, las cacas y sus datos.
struct PetView: View {
    let pet: Pet
    /// Mood forzado tras una acción (durante ~2s); si es `nil` se usa el real.
    var forcedMood: Mood?

    @State private var breathing = false
    @State private var bouncing = false

    /// Mood que realmente se muestra (forzado si lo hay).
    private var displayedMood: Mood { forcedMood ?? pet.mood }

    /// Nombre de asset a dibujar, respetando huevo y fantasma.
    private var spriteName: String {
        guard let forcedMood,
              [.baby, .child, .adult].contains(pet.stage) else {
            return pet.spriteName
        }
        return "\(pet.stage.spritePrefix)_\(forcedMood.rawValue)"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Cacas alrededor de la mascota, en posiciones deterministas.
            ForEach(0..<pet.poopCount, id: \.self) { index in
                PetSprite(assetName: "item_poop")
                    .frame(width: 22, height: 22)
                    .offset(poopOffset(for: index))
            }

            // La mascota, con respiración y (si está feliz) rebote.
            PetSprite(assetName: spriteName)
                .frame(width: 110, height: 110)
                .scaleEffect(breathing ? 1.04 : 1.0)
                .offset(y: bouncing ? -8 : 0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true),
                           value: breathing)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                           value: bouncing)

            // Nombre y edad, discretos, arriba a la izquierda.
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(pet.name)
                        Text(pet.ageDescription)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            }
            .padding(.horizontal, 6)
        }
        .onAppear {
            breathing = true
            bouncing = displayedMood == .happy
        }
        .onChange(of: displayedMood) { _, mood in
            bouncing = mood == .happy
        }
    }

    /// Posición determinista de cada caca, derivada solo del índice.
    private func poopOffset(for index: Int) -> CGSize {
        let step = 2 * Double.pi / Double(Balance.maxPoopCount)
        let angle = Double(index) * step + 0.6
        let radius: Double = 62
        return CGSize(width: cos(angle) * radius,
                      height: sin(angle) * radius * 0.5 + 40)
    }
}
