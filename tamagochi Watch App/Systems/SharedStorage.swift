import Foundation

/// Almacenamiento compartido entre la app y la complicación vía App Group.
///
/// El App Group `group.com.antonio.tamagochi` debe activarse a mano en
/// Signing & Capabilities de AMBOS targets (app y widget); hasta entonces
/// `UserDefaults(suiteName:)` funciona pero no comparte de verdad.
enum SharedStorage {
    static let appGroup = "group.com.antonio.tamagochi"
    static let petKey = "pet.v1"

    /// Defaults del grupo (con caída a `.standard` si el grupo no existe aún).
    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    /// Decodifica la mascota guardada; `nil` si no hay o está corrupta.
    static func loadPet() -> Pet? {
        guard let data = defaults.data(forKey: petKey) else { return nil }
        return try? JSONDecoder().decode(Pet.self, from: data)
    }

    /// Guarda la mascota en el grupo.
    static func save(_ pet: Pet) {
        guard let data = try? JSONEncoder().encode(pet) else { return }
        defaults.set(data, forKey: petKey)
    }
}
