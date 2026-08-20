import Foundation

/// Todas las constantes de balance del juego viven aquí.
/// Ningún número mágico debe existir fuera de este `enum`.
enum Balance {

    // MARK: - Caída de stats por hora (puntos/hora)
    static let hungerDecayPerHour: Double = 8
    static let happinessDecayPerHour: Double = 6
    static let energyDecayPerHour: Double = 5
    static let hygieneDecayPerHour: Double = 4

    // MARK: - Sueño
    /// Energía recuperada por hora mientras la mascota duerme.
    static let energyRecoveryPerHour: Double = 20
    /// Multiplicador de la caída de los demás stats mientras duerme.
    static let sleepingDecayMultiplier: Double = 0.5

    // MARK: - Cacas
    /// Horas que tardan en aparecer cada caca.
    static let hoursPerPoop: Double = 6
    /// Máximo de cacas acumuladas.
    static let maxPoopCount: Int = 5
    /// Cada caca presente acelera la caída de higiene un 50%.
    static let poopHygienePenalty: Double = 0.5

    // MARK: - Umbrales
    /// Un stat por debajo de esto se considera bajo (mood triste).
    static let lowThreshold: Double = 25
    /// Un stat por debajo de esto se considera crítico.
    static let criticalThreshold: Double = 20
    /// Todos los stats por encima de esto = mascota feliz.
    static let happyThreshold: Double = 75

    // MARK: - Enfermedad
    /// Horas enferma sin atender antes de morir.
    static let hoursSickUntilDeath: Double = 24

    // MARK: - Duración de etapas (en segundos)
    static let eggDuration: TimeInterval = 5 * 60            // 5 minutos
    static let babyDuration: TimeInterval = 24 * 60 * 60     // 1 día
    static let childDuration: TimeInterval = 3 * 24 * 60 * 60 // 3 días
    /// Último tramo antes de eclosionar en el que el huevo se muestra agrietado.
    static let eggCrackWarning: TimeInterval = 60           // 1 minuto

    // MARK: - Costos de acciones
    static let feedHungerGain: Double = 30
    static let feedHygienePenalty: Double = 5
    static let playHappinessGain: Double = 25
    static let playEnergyCost: Double = 10
    static let playHungerCost: Double = 5
    static let cleanHygieneGain: Double = 40

    // MARK: - Rango válido de todos los stats (100 = óptimo)
    static let statRange: ClosedRange<Double> = 0...100
}
