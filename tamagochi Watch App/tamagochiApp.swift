//
//  tamagochiApp.swift
//  tamagochi Watch App
//
//  Created by Antonio Teran on 20/8/26.
//

import SwiftUI

@main
struct tamagochi_Watch_AppApp: App {
    @State private var store = PetStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.refresh()
            }
        }
    }
}
