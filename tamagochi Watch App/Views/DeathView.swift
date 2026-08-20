import SwiftUI

/// Reemplaza toda la interfaz cuando la mascota ha muerto.
struct DeathView: View {
    let store: PetStore
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 10) {
                PetSprite(assetName: "pet_ghost")
                    .frame(width: 90, height: 90)
                    .foregroundStyle(.white.opacity(0.7))

                Text(store.pet.name)
                    .font(.headline)
                Text("Vivió \(store.pet.ageDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Empezar de nuevo") {
                    showResetConfirm = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
            .padding()
        }
        .confirmationDialog("¿Empezar de nuevo?",
                            isPresented: $showResetConfirm,
                            titleVisibility: .visible) {
            Button("Empezar de nuevo", role: .destructive) {
                store.reset()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Se creará una mascota nueva.")
        }
    }
}
