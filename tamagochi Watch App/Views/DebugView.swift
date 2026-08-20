#if DEBUG
import SwiftUI

/// Página de depuración (solo en builds DEBUG): manipula el estado del juego
/// y muestra los valores crudos.
struct DebugView: View {
    let store: PetStore
    @State private var showResetConfirm = false

    private let columns = [GridItem(.flexible(), spacing: 6),
                           GridItem(.flexible(), spacing: 6)]

    private static let hour: TimeInterval = 3600

    private static let stampFormat: Date.FormatStyle = .dateTime
        .month(.twoDigits).day().hour().minute().second()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 8) {
                    Text("DEBUG")
                        .font(.caption).bold()
                        .foregroundStyle(.yellow)

                    LazyVGrid(columns: columns, spacing: 6) {
                        timeButton("+1 h",  Self.hour)
                        timeButton("+6 h",  Self.hour * 6)
                        timeButton("+1 d",  Self.hour * 24)
                        timeButton("+3 d",  Self.hour * 24 * 3)
                    }

                    Button {
                        store.debugMakeFilthy()
                    } label: {
                        Label("Ensuciar", systemImage: "aqi.medium")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        store.debugKill()
                    } label: {
                        Label("Matar", systemImage: "xmark.octagon.fill")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset total", systemImage: "trash.fill")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)

                    rawStats
                }
                .padding(.horizontal, 4)
            }
        }
        .confirmationDialog("¿Reset total?",
                            isPresented: $showResetConfirm,
                            titleVisibility: .visible) {
            Button("Borrar y empezar", role: .destructive) { store.reset() }
            Button("Cancelar", role: .cancel) { }
        }
    }

    private func timeButton(_ title: String, _ interval: TimeInterval) -> some View {
        Button {
            store.debugAdvance(by: interval)
        } label: {
            Text(title)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
    }

    /// Valores crudos de todos los stats + `lastSeen`, para depurar.
    private var rawStats: some View {
        let p = store.pet
        return VStack(alignment: .leading, spacing: 1) {
            Text("hunger:    \(p.hunger, specifier: "%.1f")")
            Text("happiness: \(p.happiness, specifier: "%.1f")")
            Text("energy:    \(p.energy, specifier: "%.1f")")
            Text("hygiene:   \(p.hygiene, specifier: "%.1f")")
            Text("poop:      \(p.poopCount)")
            Text("sleeping:  \(p.isSleeping ? "yes" : "no")")
            Text("sick:      \(p.sickSince == nil ? "no" : "yes")")
            Text("dead:      \(p.isDead ? "yes" : "no")")
            Text("stage:     \(p.stage.rawValue)")
            Text("lastSeen:  \(p.lastSeen.formatted(Self.stampFormat))")
        }
        .font(.system(.caption2, design: .monospaced))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}
#endif
