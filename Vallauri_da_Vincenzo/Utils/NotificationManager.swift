import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
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
