import SwiftUI

/// Pantalla explicativa propia que precede al permiso del sistema.
struct NotificationPrimerView: View {
    let scheduler: NotificationScheduler
    /// Se llama tras decidir, para reprogramar avisos si se concedió el permiso.
    var onDecision: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 10) {
                    Text("🔔")
                        .font(.largeTitle)
                    Text("¿Te aviso?")
                        .font(.headline)
                    Text("Puedo darte un toque cuando tenga hambre, esté sucio o me sienta mal. Así no me pasa nada mientras no miras.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Vale, avísame") {
                        Task {
                            await scheduler.requestAuthorization()
                            onDecision()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Ahora no") {
                        scheduler.declinePrimer()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
    }
}
