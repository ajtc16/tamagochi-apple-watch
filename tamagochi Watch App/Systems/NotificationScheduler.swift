import Foundation
import Observation
import UserNotifications

/// Programa las notificaciones locales de la mascota.
///
/// - Muestra una pantalla explicativa propia antes de pedir el permiso del
///   sistema (ver `needsPrimer` / `NotificationPrimerView`).
/// - Tras cada acción cancela lo pendiente y recalcula CUÁNDO cada stat
///   cruzará el umbral crítico usando las constantes de `Balance`.
/// - Programa como máximo 3 avisos y respeta el horario nocturno.
@MainActor
@Observable
final class NotificationScheduler {

    /// `true` si aún debemos enseñar nuestra pantalla explicativa.
    var needsPrimer = false

    private let center = UNUserNotificationCenter.current()
    private static let primerShownKey = "notif.primerShown.v1"

    // MARK: - Permiso

    /// Decide si hay que mostrar la pantalla explicativa (solo la 1ª vez).
    func refreshPrimerState() async {
        let settings = await center.notificationSettings()
        let alreadyAsked = UserDefaults.standard.bool(forKey: Self.primerShownKey)
        needsPrimer = settings.authorizationStatus == .notDetermined && !alreadyAsked
    }

    /// Pide el permiso del sistema (tras aceptar nuestra pantalla).
    func requestAuthorization() async {
        UserDefaults.standard.set(true, forKey: Self.primerShownKey)
        needsPrimer = false
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    /// El usuario rechazó nuestra pantalla: no molestamos con el diálogo del sistema.
    func declinePrimer() {
        UserDefaults.standard.set(true, forKey: Self.primerShownKey)
        needsPrimer = false
    }

    // MARK: - Programación

    /// Cancela lo pendiente y reprograma según el estado actual de la mascota.
    func reschedule(for pet: Pet) {
        Task { await performReschedule(for: pet) }
    }

    private func performReschedule(for pet: Pet) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        center.removeAllPendingNotificationRequests()
        guard !pet.isDead else { return }

        var requests: [UNNotificationRequest] = []

        // 1. El stat que cruzará el umbral crítico primero.
        if let crossing = firstStatCrossing(pet) {
            requests.append(makeRequest(id: "stat", name: pet.name,
                                        body: crossing.message, date: crossing.date))
        }

        // 2 y 3. Enfermedad y peligro de muerte.
        let fate = sickAndDeathDates(pet)
        if let sickDate = fate.sick {   // solo si aún no está enfermo (ver más abajo)
            requests.append(makeRequest(id: "sick", name: pet.name,
                                        body: "No me siento nada bien… 🤒", date: sickDate))
        }
        if let deathDate = fate.death {
            requests.append(makeRequest(id: "death", name: pet.name,
                                        body: "Me estoy apagando… ven 👻", date: deathDate))
        }

        for request in requests {
            try? await center.add(request)
        }
    }

    // MARK: - Cálculo de cruces de umbral

    /// Devuelve el primer stat en cruzar el umbral crítico y cuándo.
    private func firstStatCrossing(_ pet: Pet) -> (message: String, date: Date)? {
        let sleepMult = pet.isSleeping ? Balance.sleepingDecayMultiplier : 1
        let poopMult = 1 + Double(pet.poopCount) * Balance.poopHygienePenalty

        // (mensaje, valor actual, caída efectiva por hora)
        var candidates: [(String, Double, Double)] = [
            ("Tengo hambre 🍎",        pet.hunger,    Balance.hungerDecayPerHour * sleepMult),
            ("Me aburro… ¿jugamos? 🎾", pet.happiness, Balance.happinessDecayPerHour * sleepMult),
            ("¡Necesito un baño! 🛁",   pet.hygiene,   Balance.hygieneDecayPerHour * poopMult * sleepMult),
        ]
        // Durmiendo la energía sube, así que no cruzará el umbral por abajo.
        if !pet.isSleeping {
            candidates.append(("Estoy agotadísimo 😴", pet.energy, Balance.energyDecayPerHour))
        }

        let soonest = candidates
            .compactMap { message, value, decay -> (String, Double)? in
                guard let hours = hoursToCritical(value: value, decayPerHour: decay) else { return nil }
                return (message, hours)
            }
            .min { $0.1 < $1.1 }

        guard let soonest else { return nil }
        let date = adjustedForNight(Date.now.addingTimeInterval(soonest.1 * 3600))
        guard date > .now else { return nil }
        return (soonest.0, date)
    }

    /// Horas hasta que `value` baje al umbral crítico, o `nil` si no baja.
    private func hoursToCritical(value: Double, decayPerHour: Double) -> Double? {
        guard value > Balance.criticalThreshold, decayPerHour > 0 else { return nil }
        return (value - Balance.criticalThreshold) / decayPerHour
    }

    /// Fechas (ya ajustadas a horario diurno) de enfermedad y muerte.
    private func sickAndDeathDates(_ pet: Pet) -> (sick: Date?, death: Date?) {
        let sleepMult = pet.isSleeping ? Balance.sleepingDecayMultiplier : 1
        let poopMult = 1 + Double(pet.poopCount) * Balance.poopHygienePenalty

        // Se enferma cuando hambre o higiene llegan a 0.
        let hungerZero = hoursToZero(pet.hunger, Balance.hungerDecayPerHour * sleepMult)
        let hygieneZero = hoursToZero(pet.hygiene, Balance.hygieneDecayPerHour * poopMult * sleepMult)
        let sickHours = [hungerZero, hygieneZero].compactMap { $0 }.min()

        let deathLead = Balance.hoursSickUntilDeath

        var sickDate: Date?
        var deathDate: Date?

        if let sickSince = pet.sickSince {
            // Ya está enfermo: no reprogramamos "enfermo", solo el peligro de muerte.
            deathDate = sickSince.addingTimeInterval(deathLead * 3600)
        } else if let sickHours {
            sickDate = Date.now.addingTimeInterval(sickHours * 3600)
            deathDate = Date.now.addingTimeInterval((sickHours + deathLead) * 3600)
        }

        let sick = sickDate.map(adjustedForNight).flatMap { $0 > .now ? $0 : nil }
        let death = deathDate.map(adjustedForNight).flatMap { $0 > .now ? $0 : nil }
        return (sick, death)
    }

    /// Horas hasta que `value` llegue a 0, o `nil` si no cae.
    private func hoursToZero(_ value: Double, _ decayPerHour: Double) -> Double? {
        guard decayPerHour > 0 else { return nil }
        return max(0, value) / decayPerHour
    }

    // MARK: - Horario nocturno

    /// Nada entre las 22:00 y las 8:00: mueve la fecha a las 8:00 del día que toque.
    private func adjustedForNight(_ date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        if hour >= 22 {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: nextDay) ?? date
        } else if hour < 8 {
            return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) ?? date
        }
        return date
    }

    // MARK: - Construcción de la notificación

    private func makeRequest(id: String, name: String, body: String, date: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = name
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }
}
