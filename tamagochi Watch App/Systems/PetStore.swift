import Foundation
import Observation
import WatchKit
import WidgetKit

/// Fuente de verdad de la mascota: persiste en el App Group, avanza la
/// simulación y expone las acciones del jugador con su háptica.
@MainActor
@Observable
final class PetStore {

    /// Nombre por defecto de una mascota nueva.
    private static let defaultName = "Tama"

    private(set) var pet: Pet

    /// Programador de notificaciones locales, enganchado a cada cambio.
    let notifications = NotificationScheduler()

    init() {
        // Si no hay nada guardado o el JSON está corrupto, empezamos de cero.
        pet = Self.loadPet() ?? Pet(name: Self.defaultName)
    }

    // MARK: - Persistencia

    /// Carga la mascota del App Group. Si no hay, intenta migrar desde el
    /// almacenamiento antiguo (`UserDefaults.standard`). Nunca crashea.
    private static func loadPet() -> Pet? {
        if let pet = SharedStorage.loadPet() { return pet }

        // Migración: datos guardados antes del App Group.
        guard let data = UserDefaults.standard.data(forKey: SharedStorage.petKey),
              let legacy = try? JSONDecoder().decode(Pet.self, from: data) else {
            return nil
        }
        SharedStorage.save(legacy)
        UserDefaults.standard.removeObject(forKey: SharedStorage.petKey)
        return legacy
    }

    private func save() {
        SharedStorage.save(pet)
        // Cada cambio de estado reprograma los avisos y refresca la complicación.
        notifications.reschedule(for: pet)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Ciclo de vida

    /// Aplica el tiempo transcurrido y persiste.
    func refresh() {
        pet.advance()
        save()
    }

    // MARK: - Acciones

    func feed() {
        pet.feed()
        save()
        WKInterfaceDevice.current().play(.click)
    }

    func play() {
        pet.play()
        save()
        WKInterfaceDevice.current().play(.success)
    }

    func clean() {
        pet.clean()
        save()
        WKInterfaceDevice.current().play(.directionUp)
    }

    func toggleSleep() {
        pet.toggleSleep()
        save()
        WKInterfaceDevice.current().play(.stop)
    }

    func heal() {
        pet.heal()
        save()
        WKInterfaceDevice.current().play(.notification)
    }

    // MARK: - Reset

    /// Borra el guardado y arranca con una mascota nueva.
    func reset() {
        SharedStorage.defaults.removeObject(forKey: SharedStorage.petKey)
        pet = Pet(name: Self.defaultName)
        save()
    }

    // MARK: - Depuración

    #if DEBUG
    /// Adelanta el reloj del juego restando tiempo a `lastSeen` y avanzando.
    func debugAdvance(by interval: TimeInterval) {
        pet.lastSeen -= interval
        pet.advance()
        save()
    }

    /// Deja a la mascota lo más sucia posible.
    func debugMakeFilthy() {
        pet.hygiene = Balance.statRange.lowerBound
        pet.poopCount = Balance.maxPoopCount
        save()
    }

    /// Mata a la mascota directamente (para probar `DeathView`).
    func debugKill() {
        pet.isDead = true
        save()
    }
    #endif
}
