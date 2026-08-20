//
//  ContentView.swift
//  tamagochi Watch App
//
//  Created by Antonio Teran on 20/8/26.
//

import SwiftUI

struct ContentView: View {
    let store: PetStore

    @State private var selectedPage = 0
    @State private var forcedMood: Mood?
    @State private var forcedMoodTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Group {
                if store.pet.isDead {
                    DeathView(store: store)
                } else {
                    TabView(selection: $selectedPage) {
                        PetView(pet: store.pet, forcedMood: forcedMood)
                            .tag(0)
                        StatsView(pet: store.pet)
                            .tag(1)
                        ActionsView(store: store) { mood in
                            showActionMood(mood)
                        }
                        .tag(2)

                        #if DEBUG
                        DebugView(store: store)
                            .tag(3)
                        #endif
                    }
                    .tabViewStyle(.verticalPage)
                }
            }
            .background(Color.black)

            // Pantalla explicativa propia antes del permiso del sistema.
            if store.notifications.needsPrimer {
                NotificationPrimerView(scheduler: store.notifications) {
                    store.notifications.reschedule(for: store.pet)
                }
            }
        }
        .task {
            await store.notifications.refreshPrimerState()
        }
    }

    /// Fuerza el sprite del mood de la acción, vuelve a la página 1 y lo
    /// mantiene 2 segundos antes de restaurar el mood normal.
    private func showActionMood(_ mood: Mood) {
        forcedMood = mood
        withAnimation { selectedPage = 0 }

        forcedMoodTask?.cancel()
        forcedMoodTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            forcedMood = nil
        }
    }
}

#Preview {
    ContentView(store: PetStore())
}
