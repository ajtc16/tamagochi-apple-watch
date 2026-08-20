import SwiftUI

/// Página 3: los botones de acción en grid.
struct ActionsView: View {
    let store: PetStore
    /// Se llama tras cada acción con el mood a mostrar en la página 1.
    var onAction: (Mood) -> Void

    private let columns = [GridItem(.flexible(), spacing: 6),
                           GridItem(.flexible(), spacing: 6)]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 6) {
                    actionButton("Alimentar", systemImage: "fork.knife") {
                        store.feed()
                        onAction(.eating)
                    }

                    actionButton("Jugar", systemImage: "figure.play") {
                        store.play()
                        onAction(.happy)
                    }

                    actionButton("Limpiar", systemImage: "bubbles.and.sparkles.fill",
                                 disabled: store.pet.poopCount == 0) {
                        store.clean()
                        onAction(.happy)
                    }

                    actionButton(store.pet.isSleeping ? "Despertar" : "Dormir",
                                 systemImage: store.pet.isSleeping ? "sun.max.fill" : "moon.zzz.fill") {
                        store.toggleSleep()
                        onAction(store.pet.isSleeping ? .sleeping : .idle)
                    }

                    actionButton("Curar", systemImage: "cross.case.fill",
                                 disabled: store.pet.sickSince == nil) {
                        store.heal()
                        onAction(.happy)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func actionButton(_ title: String,
                              systemImage: String,
                              disabled: Bool = false,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .disabled(disabled)
    }
}
