import Foundation

// MARK: - LifeStage

enum LifeStage: String, Codable, CaseIterable {
    case egg, baby, child, adult, ghost

    /// Prefijo del sprite asociado a la etapa.
    var spritePrefix: String {
        switch self {
        case .egg:   return "pet_egg"
        case .baby:  return "pet_baby"
        case .child: return "pet_child"
        case .adult: return "pet_adult"
        case .ghost: return "pet_ghost"
        }
    }
}

// MARK: - Mood

enum Mood: String {
    case idle, happy, eating, sleeping, sad, sick
}

// MARK: - Pet

struct Pet: Codable, Equatable {
    var name: String
    var birth: Date
    var lastSeen: Date
    var sickSince: Date?

    /// Stats en el rango 0...100, donde 100 es óptimo.
    var hunger: Double
    var happiness: Double
    var energy: Double
    var hygiene: Double

    var isSleeping: Bool
    var poopCount: Int
    var isDead: Bool

    /// Crea una mascota nueva (huevo recién puesto) con todos los stats al máximo.
    init(name: String, birth: Date = .now) {
        self.name = name
        self.birth = birth
        self.lastSeen = birth
        self.sickSince = nil
        self.hunger = Balance.statRange.upperBound
        self.happiness = Balance.statRange.upperBound
        self.energy = Balance.statRange.upperBound
        self.hygiene = Balance.statRange.upperBound
        self.isSleeping = false
        self.poopCount = 0
        self.isDead = false
    }

    // MARK: - Simulación del tiempo transcurrido

    /// Avanza la simulación desde `lastSeen` hasta `now`, aplicando caídas de
    /// stats, generación de cacas, enfermedad y muerte.
    mutating func advance(to now: Date = .now) {
        // Una mascota muerta ya no evoluciona; solo actualizamos la marca.
        guard !isDead else {
            lastSeen = now
            return
        }

        let elapsedHours = now.timeIntervalSince(lastSeen) / 3600
        guard elapsedHours > 0 else { return }

        // Cacas: una cada `hoursPerPoop`, tope en `maxPoopCount`.
        let newPoops = Int(elapsedHours / Balance.hoursPerPoop)
        poopCount = min(Balance.maxPoopCount, poopCount + newPoops)

        // Cada caca acelera la caída de higiene un 50%.
        let hygieneMultiplier = 1 + Double(poopCount) * Balance.poopHygienePenalty

        // Mientras duerme la energía sube y los demás stats caen a la mitad.
        let decayMultiplier = isSleeping ? Balance.sleepingDecayMultiplier : 1

        hunger    -= Balance.hungerDecayPerHour    * elapsedHours * decayMultiplier
        happiness -= Balance.happinessDecayPerHour * elapsedHours * decayMultiplier
        hygiene   -= Balance.hygieneDecayPerHour   * hygieneMultiplier * elapsedHours * decayMultiplier

        if isSleeping {
            energy += Balance.energyRecoveryPerHour * elapsedHours
        } else {
            energy -= Balance.energyDecayPerHour * elapsedHours
        }

        clampStats()

        // Se enferma si el hambre o la higiene tocan fondo.
        if hunger <= Balance.statRange.lowerBound || hygiene <= Balance.statRange.lowerBound {
            if sickSince == nil { sickSince = now }
        }

        // Muere si lleva demasiadas horas enferma sin atender.
        if let sickSince,
           now.timeIntervalSince(sickSince) >= Balance.hoursSickUntilDeath * 3600 {
            isDead = true
        }

        lastSeen = now
    }

    // MARK: - Etapa de vida

    var stage: LifeStage {
        if isDead { return .ghost }

        let age = Date.now.timeIntervalSince(birth)
        let babyEnds = Balance.eggDuration + Balance.babyDuration
        let childEnds = babyEnds + Balance.childDuration

        switch age {
        case ..<Balance.eggDuration: return .egg
        case ..<babyEnds:            return .baby
        case ..<childEnds:           return .child
        default:                     return .adult
        }
    }

    // MARK: - Estado de ánimo

    /// Prioridad: sleeping > sick > sad > happy > idle.
    var mood: Mood {
        if isSleeping { return .sleeping }
        if sickSince != nil { return .sick }

        let stats = [hunger, happiness, energy, hygiene]
        if stats.contains(where: { $0 < Balance.lowThreshold }) { return .sad }
        if stats.allSatisfy({ $0 > Balance.happyThreshold }) { return .happy }
        return .idle
    }

    // MARK: - Sprite

    var spriteName: String {
        switch stage {
        case .egg:
            let timeToHatch = birth
                .addingTimeInterval(Balance.eggDuration)
                .timeIntervalSince(.now)
            return timeToHatch < Balance.eggCrackWarning ? "pet_egg_cracked" : "pet_egg_idle"
        case .ghost:
            return "pet_ghost"
        default:
            return "\(stage.spritePrefix)_\(mood.rawValue)"
        }
    }

    // MARK: - Edad legible

    /// Formatea la edad como "3d 4h" o "5h 20m".
    var ageDescription: String {
        let age = Date.now.timeIntervalSince(birth)
        let totalMinutes = max(0, Int(age / 60))
        let days = totalMinutes / (60 * 24)
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }

    // MARK: - Acciones

    /// Alimenta a la mascota. No hace nada si el hambre ya está al máximo.
    mutating func feed() {
        guard hunger < Balance.statRange.upperBound else { return }
        hunger += Balance.feedHungerGain
        hygiene -= Balance.feedHygienePenalty
        clampStats()
    }

    /// Juega: sube la felicidad pero cansa y da algo de hambre.
    mutating func play() {
        happiness += Balance.playHappinessGain
        energy -= Balance.playEnergyCost
        hunger -= Balance.playHungerCost
        clampStats()
    }

    /// Limpia: elimina todas las cacas y sube la higiene.
    mutating func clean() {
        poopCount = 0
        hygiene += Balance.cleanHygieneGain
        clampStats()
    }

    /// Alterna entre dormir y despertar.
    mutating func toggleSleep() {
        isSleeping.toggle()
    }

    /// Cura la enfermedad.
    mutating func heal() {
        sickSince = nil
    }

    // MARK: - Utilidades

    private mutating func clampStats() {
        hunger = clamp(hunger)
        happiness = clamp(happiness)
        energy = clamp(energy)
        hygiene = clamp(hygiene)
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, Balance.statRange.lowerBound), Balance.statRange.upperBound)
    }
}
