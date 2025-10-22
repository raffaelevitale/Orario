import Foundation
import UserNotifications

// MARK: - Notification Configuration

/// Configurazione riutilizzabile per le notifiche
struct NotificationConfig {
    let identifier: String
    let title: String
    let body: String
    let sound: UNNotificationSound
    let categoryIdentifier: String?
    let interruptionLevel: UNNotificationInterruptionLevel
    let badge: NSNumber?

    /// Configurazione di default per notifiche standard
    static func standard(id: String, title: String, body: String) -> NotificationConfig {
        NotificationConfig(
            identifier: id,
            title: title,
            body: body,
            sound: .default,
            categoryIdentifier: nil,
            interruptionLevel: .active,
            badge: nil
        )
    }

    /// Configurazione per notifiche time-sensitive
    static func timeSensitive(id: String, title: String, body: String) -> NotificationConfig {
        NotificationConfig(
            identifier: id,
            title: title,
            body: body,
            sound: .defaultCritical,
            categoryIdentifier: "LESSON_CATEGORY",
            interruptionLevel: .timeSensitive,
            badge: 1
        )
    }
}

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    // MARK: - Helper Methods

    /// Crea contenuto notifica da configurazione
    private func createNotificationContent(from config: NotificationConfig) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = config.title
        content.body = config.body
        content.sound = config.sound

        if let category = config.categoryIdentifier {
            content.categoryIdentifier = category
        }

        if #available(iOS 15.0, *) {
            content.interruptionLevel = config.interruptionLevel
        }

        if let badge = config.badge {
            content.badge = badge
        }

        return content
    }

    /// Schedule a notification with given config and trigger
    private func scheduleNotification(
        config: NotificationConfig,
        trigger: UNNotificationTrigger,
        completion: ((Result<Void, AppError>) -> Void)? = nil
    ) {
        let content = createNotificationContent(from: config)
        let request = UNNotificationRequest(
            identifier: config.identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Errore scheduling notifica \(config.identifier): \(error)")
                completion?(.failure(.notificationSchedulingFailed(error)))
            } else {
                print("✅ Notifica programmata: \(config.identifier)")
                completion?(.success(()))
            }
        }
    }
    
    // MARK: - Configurazioni Avanzate
    
    /// Programma notifiche usando le configurazioni avanzate
    func scheduleAdvancedNotifications(for lessons: [Lesson], settings: NotificationSettings) {
        // Verifica prima i permessi
        UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
            guard notificationSettings.authorizationStatus == .authorized else {
                print("Permessi notifiche non concessi")
                return
            }
            
            DispatchQueue.main.async {
                // Rimuovi tutte le notifiche esistenti
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                
                // Aspetta un momento per assicurarsi che le notifiche siano rimosse
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.processAdvancedScheduling(lessons: lessons, settings: settings)
                }
            }
        }
    }
    
    private func processAdvancedScheduling(lessons: [Lesson], settings: NotificationSettings) {
        guard settings.enableNotifications else { return }
        
        // Programma promemoria per lezioni con configurazioni avanzate
        if settings.enableLessonReminders {
            for lesson in lessons {
                self.scheduleAdvancedLessonNotification(lesson: lesson, settings: settings)
            }
        }
        
        // Programma notifica quotidiana con configurazioni avanzate
        if settings.enableDailyNotification {
            self.scheduleAdvancedDailyNotification(lessons: lessons, settings: settings)
        }
        
        // Programma promemoria personalizzati
        for reminder in settings.customReminders where reminder.isEnabled {
            self.scheduleCustomReminder(reminder: reminder, settings: settings)
        }
    }
    
    private func scheduleAdvancedLessonNotification(lesson: Lesson, settings: NotificationSettings) {
        // Verifica se le notifiche sono attive per questo momento
        let currentDate = Date()
        guard settings.areNotificationsActiveAt(currentDate) else { return }
        
        // Ottieni configurazione specifica per la materia
        let subjectConfig = settings.configForSubject(lesson.subject) ?? SubjectNotificationConfig(subjectName: lesson.subject)
        
        guard subjectConfig.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = lesson.subject
        
        // Personalizza il messaggio in base alla priorità
        switch subjectConfig.priority {
        case .critical:
            content.body = "🚨 IMPORTANTE: \(lesson.subject) tra \(subjectConfig.reminderMinutes) minuti - Aula: \(lesson.classroom)"
        case .high:
            content.body = "⚡ \(lesson.subject) tra \(subjectConfig.reminderMinutes) minuti - Aula: \(lesson.classroom)"
        case .normal:
            content.body = "📚 \(lesson.subject) tra \(subjectConfig.reminderMinutes) minuti - Aula: \(lesson.classroom)"
        case .low:
            content.body = "\(lesson.subject) tra \(subjectConfig.reminderMinutes) minuti - Aula: \(lesson.classroom)"
        }
        
        if !lesson.teacher.isEmpty {
            content.subtitle = "Prof. \(lesson.teacher)"
        }
        
        // Imposta suono personalizzato se specificato
        if let customSound = subjectConfig.customSound {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(customSound))
        } else {
            content.sound = .default
        }
        
        // Calcola l'orario di notifica
        let timeComponents = lesson.startTime.components(separatedBy: ":")
        guard let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            print("❌ Errore nel parsing dell'orario: \(lesson.startTime)")
            return
        }
        
        var notificationMinute = minute - subjectConfig.reminderMinutes
        var notificationHour = hour
        
        if notificationMinute < 0 {
            notificationMinute += 60
            notificationHour -= 1
        }
        
        guard notificationHour >= 0 && notificationHour < 24,
              notificationMinute >= 0 && notificationMinute < 60 else {
            print("Orario notifica non valido: \(notificationHour):\(notificationMinute)")
            return
        }
        
        // Verifica se abilitare notifiche weekend
        let isWeekend = lesson.dayOfWeek == 6 || lesson.dayOfWeek == 0 // Sabato o Domenica
        guard !isWeekend || subjectConfig.enableWeekendReminders else { return }
        
        // Crea il trigger per ogni settimana
        var dateComponents = DateComponents()
        dateComponents.weekday = (lesson.dayOfWeek % 7) + 1
        dateComponents.hour = notificationHour
        dateComponents.minute = notificationMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "advanced-lesson-\(lesson.id)-\(lesson.dayOfWeek)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Errore scheduling notifica avanzata per \(lesson.subject): \(error)")
            } else {
                print("Notifica avanzata programmata per \(lesson.subject) - \(dateComponents.weekday!) alle \(notificationHour):\(String(format: "%02d", notificationMinute))")
                
                // Registra evento per analytics
                let event = NotificationEvent(
                    type: .lessonReminder,
                    subjectName: lesson.subject,
                    wasDelivered: true
                )
                SettingsManager.shared.recordNotificationEvent(event)
            }
        }
    }
    
    private func scheduleAdvancedDailyNotification(lessons: [Lesson], settings: NotificationSettings) {
        let calendar = Calendar.current
        let notificationTime = settings.dailyNotificationTime
        let hour = calendar.component(.hour, from: notificationTime)
        let minute = calendar.component(.minute, from: notificationTime)
        
        // Programma notifiche per ogni giorno della settimana
        for dayOfWeek in 1...7 {
            guard let dayOfWeekEnum = DaySchedule.DayOfWeek.allCases.first(where: { 
                $0.weekdayComponent == dayOfWeek + 1 
            }),
            let daySchedule = settings.scheduleForDay(dayOfWeekEnum) else { 
                continue 
            }
            
            guard daySchedule.isEnabled else { continue }
            
            let todayLessons = lessons.filter { 
                $0.dayOfWeek == dayOfWeek && $0.subject != "Intervallo" 
            }.sorted { $0.startTime < $1.startTime }
            
            guard !todayLessons.isEmpty else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "📚 Buona scuola!"
            
            // Filtra lezioni in base alle configurazioni delle materie
            let enabledLessons = todayLessons.filter { lesson in
                let config = settings.configForSubject(lesson.subject)
                return config?.isEnabled ?? true
            }
            
            if enabledLessons.isEmpty { continue }
            
            // Crea l'elenco delle materie
            let subjects = enabledLessons.map { $0.subject }
            let uniqueSubjects = Array(Set(subjects)).sorted()
            
            if settings.enableSmartScheduling {
                // Notifica intelligente con informazioni sul carico di lavoro
                content.body = generateSmartDailyMessage(subjects: uniqueSubjects, lessons: enabledLessons, settings: settings)
            } else {
                // Notifica standard
                content.body = generateStandardDailyMessage(subjects: uniqueSubjects)
            }
            
            content.sound = .default
            content.badge = 1
            
            // Verifica ore di silenzio
            let proposedTime = calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
            if let quietHours = daySchedule.quietHours ?? (settings.globalQuietHours.isEnabled ? settings.globalQuietHours : nil) {
                if isTimeInQuietHours(proposedTime, quietHours: quietHours) {
                    continue // Salta questo giorno se è nelle ore di silenzio
                }
            }
            
            var dateComponents = DateComponents()
            dateComponents.weekday = dayOfWeek + 1
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "advanced-daily-\(dayOfWeek)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Errore programmazione notifica quotidiana avanzata per giorno \(dayOfWeek): \(error)")
                } else {
                    let dayName = calendar.weekdaySymbols[dayOfWeek - 1]
                    print("✅ Notifica quotidiana avanzata programmata per \(dayName) alle \(String(format: "%02d:%02d", hour, minute))")
                }
            }
        }
    }
    
    private func scheduleCustomReminder(reminder: CustomReminder, settings: NotificationSettings) {
        let content = UNMutableNotificationContent()
        content.title = "🔔 Promemoria"
        content.body = reminder.title
        content.sound = .default
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminder.time)
        let minute = calendar.component(.minute, from: reminder.time)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // Gestisci pattern di ripetizione
        let trigger: UNNotificationTrigger
        switch reminder.repeatPattern {
        case .daily:
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        case .weekdays:
            // Programma per lunedì-venerdì
            for weekday in 2...6 {
                var weekdayComponents = dateComponents
                weekdayComponents.weekday = weekday
                let weekdayTrigger = UNCalendarNotificationTrigger(dateMatching: weekdayComponents, repeats: true)
                
                let request = UNNotificationRequest(
                    identifier: "custom-reminder-\(reminder.id)-\(weekday)",
                    content: content,
                    trigger: weekdayTrigger
                )
                
                UNUserNotificationCenter.current().add(request)
            }
            return
        case .weekly:
            let weekday = calendar.component(.weekday, from: reminder.time)
            dateComponents.weekday = weekday
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        case .never, .custom:
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        }
        
        let request = UNNotificationRequest(
            identifier: "custom-reminder-\(reminder.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Errore programmazione promemoria personalizzato: \(error)")
            } else {
                print("✅ Promemoria personalizzato programmato: \(reminder.title)")
            }
        }
    }
    
    // MARK: - Metodi di Utilità Avanzati
    
    private func generateSmartDailyMessage(subjects: [String], lessons: [Lesson], settings: NotificationSettings) -> String {
        let subjectCount = subjects.count
        
        if subjectCount == 1 {
            return "Oggi hai: \(subjects[0]). Concentrati e dai il massimo! 🎯"
        } else if subjectCount <= 3 {
            return "Oggi hai \(subjectCount) materie: \(subjects.joined(separator: ", ")). Organizza bene la giornata! 📝"
        } else {
            let heavyLoad = subjectCount > 5
            let motivationalMessage = heavyLoad ? "Giornata intensa ma ce la puoi fare! 💪" : "Buona giornata di studio! 📚"
            return "Oggi hai \(subjectCount) materie. \(motivationalMessage)"
        }
    }
    
    private func generateStandardDailyMessage(subjects: [String]) -> String {
        if subjects.count == 1 {
            return "Oggi hai: \(subjects[0]). Buona giornata! 🎓"
        } else if subjects.count <= 3 {
            let subjectsList = subjects.joined(separator: ", ")
            return "Oggi hai: \(subjectsList). Buona giornata! 🎓"
        } else {
            return "Oggi hai \(subjects.count) materie: \(subjects.prefix(3).joined(separator: ", ")) e altre. Buona giornata! 🎓"
        }
    }
    
    private func isTimeInQuietHours(_ time: Date, quietHours: QuietHours) -> Bool {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        let startComponents = calendar.dateComponents([.hour, .minute], from: quietHours.startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: quietHours.endTime)
        
        let currentMinutes = (timeComponents.hour ?? 0) * 60 + (timeComponents.minute ?? 0)
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        if startMinutes <= endMinutes {
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }
    
    // MARK: - Metodi Legacy (mantenuti per compatibilità)
    
    func scheduleNotifications(for lessons: [Lesson]) {
        // Verifica prima i permessi
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("Permessi notifiche non concessi")
                return
            }
            
            DispatchQueue.main.async {
                // Rimuovi tutte le notifiche esistenti
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                
                // Aspetta un momento per assicurarsi che le notifiche siano rimosse
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Programma i promemoria delle lezioni se abilitati
                    if SettingsManager.shared.enableLessonReminders {
                        for lesson in lessons {
                            self.scheduleWeeklyNotification(for: lesson)
                        }
                    }
                    
                    // Programma anche la notifica quotidiana se abilitata
                    if SettingsManager.shared.enableDailyNotification {
                        self.scheduleDailySchoolNotification(for: lessons)
                    }
                }
            }
        }
    }
    
    private func scheduleWeeklyNotification(for lesson: Lesson) {
        let content = UNMutableNotificationContent()
        content.title = lesson.subject
        // Personalizza il messaggio per intervalli e lezioni
        if lesson.subject == "Intervallo" {
            content.body = "Intervallo tra 5 minuti - \(lesson.classroom)"
        } else {
            content.body = "Lezione tra 5 minuti - Aula: \(lesson.classroom)"
        }

        if !lesson.teacher.isEmpty {
            content.subtitle = "Prof. \(lesson.teacher)"
        }
        content.sound = .default

        // Calcola l'orario di notifica (5 minuti prima)
        let timeComponents = lesson.startTime.components(separatedBy: ":")
        guard let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            print("❌ Errore nel parsing dell'orario: \(lesson.startTime)")
            return
        }

        var notificationMinute = minute - 5
        var notificationHour = hour

        if notificationMinute < 0 {
            notificationMinute += 60
            notificationHour -= 1
        }

        guard notificationHour >= 0 && notificationHour < 24,
              notificationMinute >= 0 && notificationMinute < 60 else {
            print("Orario notifica non valido: \(notificationHour):\(notificationMinute)")
            return
        }

        // Crea il trigger per ogni settimana
        var dateComponents = DateComponents()
        // weekday: 1=Sunday, 2=Monday, etc.
        dateComponents.weekday = (lesson.dayOfWeek % 7) + 1
        dateComponents.hour = notificationHour
        dateComponents.minute = notificationMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "lesson-\(lesson.id)-\(lesson.dayOfWeek)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Errore scheduling notifica per \(lesson.subject): \(error)")
            } else {
                print("Notifica programmata per \(lesson.subject) - \(dateComponents.weekday!) alle \(notificationHour):\(String(format: "%02d", notificationMinute))")
            }
        }
    }
    
    // MARK: - Daily School Notification
    
    func scheduleDailySchoolNotification(for lessons: [Lesson]) {
        // Ottieni l'orario impostato dall'utente
        let calendar = Calendar.current
        let notificationTime = SettingsManager.shared.dailyNotificationTime
        let hour = calendar.component(.hour, from: notificationTime)
        let minute = calendar.component(.minute, from: notificationTime)
        
        // Programma notifiche per ogni giorno della settimana (Lunedì-Venerdì)
        for dayOfWeek in 1...5 {
            let todayLessons = lessons.filter { 
                $0.dayOfWeek == dayOfWeek && $0.subject != "Intervallo" 
            }.sorted { $0.startTime < $1.startTime }
            
            guard !todayLessons.isEmpty else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "📚 Buona scuola!"
            
            // Crea l'elenco delle materie
            let subjects = todayLessons.map { $0.subject }
            let uniqueSubjects = Array(Set(subjects)).sorted()
            
            if uniqueSubjects.count == 1 {
                content.body = "Oggi hai: \(uniqueSubjects[0]). Buona giornata! 🎓"
            } else if uniqueSubjects.count <= 3 {
                let subjectsList = uniqueSubjects.joined(separator: ", ")
                content.body = "Oggi hai: \(subjectsList). Buona giornata! 🎓"
            } else {
                content.body = "Oggi hai \(uniqueSubjects.count) materie: \(uniqueSubjects.prefix(3).joined(separator: ", ")) e altre. Buona giornata! 🎓"
            }
            
            content.sound = .default
            content.badge = 1
            
            // Programma per l'orario impostato dall'utente
            var dateComponents = DateComponents()
            dateComponents.weekday = (dayOfWeek % 7) + 1 // Convert to Sunday=1 system
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "daily-school-\(dayOfWeek)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Errore programmazione notifica quotidiana per giorno \(dayOfWeek): \(error)")
                } else {
                    let dayName = ["", "Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì"][dayOfWeek]
                    print("✅ Notifica quotidiana programmata per \(dayName) alle \(String(format: "%02d:%02d", hour, minute))")
                }
            }
        }
    }
    
    func cancelDailySchoolNotifications() {
        let identifiers = (1...5).map { "daily-school-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Notifiche quotidiane cancellate")
    }

    func requestPermissions(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Permessi notifiche concessi")
                } else if let error = error {
                    print("Errore permessi notifiche: \(error)")
                } else {
                    print("Permessi notifiche negati dall'utente")
                }
                completion(granted)
            }
        }
    }
    
    // MARK: - Metodi di Test
    
    // Metodo per testare le notifiche immediatamente
    func sendTestNotification(for lesson: Lesson? = nil) {
        let content = UNMutableNotificationContent()
        
        if let lesson = lesson {
            content.title = lesson.subject
            content.body = "Test notifica - Aula: \(lesson.classroom)"
            content.subtitle = "Prof. \(lesson.teacher)"
        } else {
            content.title = "Test Notifica"
            content.body = "Questa è una notifica di test"
            content.subtitle = "Vallauri App"
        }
        
        content.sound = .default
        
        // Trigger immediato (tra 1 secondo)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test-notification-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Errore invio notifica test: \(error)")
            } else {
                print("Notifica test inviata!")
            }
        }
    }
    
    // Metodo per testare con una notifica programmata tra X secondi
    func scheduleTestNotification(in seconds: TimeInterval, for lesson: Lesson? = nil) {
        let content = UNMutableNotificationContent()

        if let lesson = lesson {
            content.title = lesson.subject
            content.body = "Test programmato - Aula: \(lesson.classroom)"
            content.subtitle = "Prof. \(lesson.teacher)"
        } else {
            content.title = "Test Programmato"
            content.body = "Notifica programmata tra \(Int(seconds)) secondi"
            content.subtitle = "Vallauri App"
        }

        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)

        let request = UNNotificationRequest(
            identifier: "scheduled-test-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Errore programmazione notifica test: \(error)")
            } else {
                print("Notifica test programmata per tra \(Int(seconds)) secondi!")
            }
        }
    }
        
    // Forza una notifica per una lezione specifica ADESSO
    func forceNotificationForLesson(_ lesson: Lesson) {
        let content = UNMutableNotificationContent()
        content.title = "🔔 \(lesson.subject)"
        content.body = "Lezione ADESSO - Aula: \(lesson.classroom)"
        content.subtitle = "Prof. \(lesson.teacher)"
        content.sound = .default
        content.badge = 1

        // Trigger immediato
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "force-lesson-\(lesson.id)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Errore notifica forzata per \(lesson.subject): \(error)")
            } else {
                print("Notifica forzata inviata per \(lesson.subject)!")
            }
        }
    }
        
    // Testa il sistema completo di notifiche
    func runCompleteTest() {
        print("🧪 Inizio test completo notifiche...")

        // 1. Verifica permessi
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📋 Status permessi: \(settings.authorizationStatus.rawValue)")
            print("📋 Alert: \(settings.alertSetting.rawValue)")
            print("📋 Sound: \(settings.soundSetting.rawValue)")
            print("📋 Badge: \(settings.badgeSetting.rawValue)")

            if settings.authorizationStatus != .authorized {
                print("❌ Permessi non concessi!")
                return
            }

            // 2. Test notifica immediata
            print("📨 Invio notifica test immediata...")
            self.sendTestNotification()

            // 3. Test notifica programmata
            print("⏰ Programmazione notifica test tra 5 secondi...")
            self.scheduleTestNotification(in: 5)

            // 4. Verifica notifiche programmate
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.debugScheduledNotifications()
            }
        }
    }
        
    // MARK: - Debug
        
    // Metodo per debug - verifica le notifiche programmate
    func debugScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📱 Notifiche programmate: \(requests.count)")
            for request in requests {
                print("   ID: \(request.identifier)")
                print("   Titolo: \(request.content.title)")
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("   Trigger calendario: \(trigger.dateComponents)")
                } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    print("   Trigger tempo: \(trigger.timeInterval)s")
                }
                print("   ---")
            }
        }
    }
        
    // Cancella tutte le notifiche di test
    func clearTestNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let testIds = requests.filter {
                $0.identifier.contains("test") || $0.identifier.contains("force")
            }.map { $0.identifier }

            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: testIds)
            print("🗑️ Cancellate \(testIds.count) notifiche di test")
        }
    }
        
    // Mostra tutte le notifiche consegnate
    func debugDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            print("📬 Notifiche consegnate: \(notifications.count)")
            for notification in notifications {
                print("   \(notification.request.identifier): \(notification.request.content.title)")
            }
        }
    }
}
