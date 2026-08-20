import Foundation
import Observation
import WatchKit

/// Fuente de verdad de la mascota: persiste en `UserDefaults`, avanza la
/// simulación y expone las acciones del jugador con su háptica.
@Observable
final class PetStore {

    /// Clave de almacenamiento en `UserDefaults`.
    private static let storageKey = "pet.v1"
    /// Nombre por defecto de una mascota nueva.
    private static let defaultName = "Tama"

    private(set) var pet: Pet

    init() {
        // Si no hay nada guardado o el JSON está corrupto, empezamos de cero.
        pet = Self.loadPet() ?? Pet(name: Self.defaultName)
    }

    // MARK: - Persistencia

    /// Carga la mascota guardada. Devuelve `nil` ante datos ausentes o corruptos;
    /// nunca lanza ni crashea.
    private static func loadPet() -> Pet? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(Pet.self, from: data)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(pet) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
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
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
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
