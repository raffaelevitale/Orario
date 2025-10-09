import Foundation

// MARK: - Modelli per Configurazione Avanzata Notifiche

/// Configurazioni specifiche per materia
struct SubjectNotificationConfig: Codable, Identifiable, Equatable {
    let id = UUID()
    var subjectName: String
    var isEnabled: Bool = true
    var reminderMinutes: Int = 5
    var customSound: String? = nil
    var priority: NotificationPriority = .normal
    var enableWeekendReminders: Bool = false
    
    enum NotificationPriority: String, CaseIterable, Codable {
        case low = "Bassa"
        case normal = "Normale" 
        case high = "Alta"
        case critical = "Critica"
    }
    
    static func == (lhs: SubjectNotificationConfig, rhs: SubjectNotificationConfig) -> Bool {
        return lhs.id == rhs.id &&
               lhs.subjectName == rhs.subjectName &&
               lhs.isEnabled == rhs.isEnabled &&
               lhs.reminderMinutes == rhs.reminderMinutes &&
               lhs.customSound == rhs.customSound &&
               lhs.priority == rhs.priority &&
               lhs.enableWeekendReminders == rhs.enableWeekendReminders
    }
}

/// Configurazione orari per giorno specifico
struct DaySchedule: Codable, Identifiable, Equatable {
    let id = UUID()
    var dayOfWeek: DayOfWeek
    var isEnabled: Bool = true
    var startTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    var endTime: Date = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    var quietHours: QuietHours?
    var customReminders: [CustomReminder] = []
    
    enum DayOfWeek: String, CaseIterable, Codable {
        case monday = "Lunedì"
        case tuesday = "Martedì" 
        case wednesday = "Mercoledì"
        case thursday = "Giovedì"
        case friday = "Venerdì"
        case saturday = "Sabato"
        case sunday = "Domenica"
        
        var weekdayComponent: Int {
            switch self {
            case .sunday: return 1
            case .monday: return 2
            case .tuesday: return 3
            case .wednesday: return 4
            case .thursday: return 5
            case .friday: return 6
            case .saturday: return 7
            }
        }
    }
    
    static func == (lhs: DaySchedule, rhs: DaySchedule) -> Bool {
        return lhs.id == rhs.id &&
               lhs.dayOfWeek == rhs.dayOfWeek &&
               lhs.isEnabled == rhs.isEnabled &&
               lhs.startTime == rhs.startTime &&
               lhs.endTime == rhs.endTime &&
               lhs.quietHours == rhs.quietHours &&
               lhs.customReminders == rhs.customReminders
    }
}

/// Ore di silenzio
struct QuietHours: Codable, Equatable {
    var startTime: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var endTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    var isEnabled: Bool = true
    var allowCriticalNotifications: Bool = true
    
    static func == (lhs: QuietHours, rhs: QuietHours) -> Bool {
        return lhs.startTime == rhs.startTime &&
               lhs.endTime == rhs.endTime &&
               lhs.isEnabled == rhs.isEnabled &&
               lhs.allowCriticalNotifications == rhs.allowCriticalNotifications
    }
}

/// Promemoria personalizzato
struct CustomReminder: Codable, Identifiable, Equatable {
    let id = UUID()
    var title: String
    var time: Date
    var isEnabled: Bool = true
    var repeatPattern: RepeatPattern = .never
    var associatedSubjects: [String] = []
    
    enum RepeatPattern: String, CaseIterable, Codable {
        case never = "Mai"
        case daily = "Giornaliero"
        case weekdays = "Giorni feriali"
        case weekly = "Settimanale"
        case custom = "Personalizzato"
    }
    
    static func == (lhs: CustomReminder, rhs: CustomReminder) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.time == rhs.time &&
               lhs.isEnabled == rhs.isEnabled &&
               lhs.repeatPattern == rhs.repeatPattern &&
               lhs.associatedSubjects == rhs.associatedSubjects
    }
}

/// Configurazioni avanzate complete
struct NotificationSettings: Codable {
    // Controlli Base (mantenuti per compatibilità)
    var enableNotifications: Bool = true
    var enableLessonReminders: Bool = true
    var enableDailyNotification: Bool = true
    var dailyNotificationTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    
    // Configurazione Avanzata
    var subjectConfigs: [SubjectNotificationConfig] = []
    var defaultReminderMinutes: Int = 5
    var enableSmartScheduling: Bool = false
    var adaptiveNotifications: Bool = false
    var locationBasedNotifications: Bool = false
    
    // Scheduling Personalizzato  
    var daySchedules: [DaySchedule] = []
    var globalQuietHours: QuietHours = QuietHours()
    var customReminders: [CustomReminder] = []
    var holidayScheduling: Bool = false
    
    // Analytics & Debug
    var enableAnalytics: Bool = true
    var debugMode: Bool = false
    var notificationHistory: [NotificationEvent] = []
    var performanceMetrics: NotificationMetrics = NotificationMetrics()
    
    /// Inizializzazione con configurazioni predefinite
    init() {
        setupDefaultDaySchedules()
        setupDefaultSubjectConfigs()
    }
    
    private mutating func setupDefaultDaySchedules() {
        daySchedules = DaySchedule.DayOfWeek.allCases.map { day in
            DaySchedule(dayOfWeek: day)
        }
    }
    
    private mutating func setupDefaultSubjectConfigs() {
        // Configurazioni predefinite per materie comuni
        let defaultSubjects = [
            "Matematica", "Italiano", "Inglese", "Storia", "Geografia",
            "Scienze", "Fisica", "Chimica", "Informatica", "Arte",
            "Educazione Fisica", "Filosofia", "Latino", "Economia"
        ]
        
        subjectConfigs = defaultSubjects.map { subject in
            SubjectNotificationConfig(subjectName: subject)
        }
    }
}

/// Eventi di notifica per analytics
struct NotificationEvent: Codable, Identifiable {
    let id = UUID()
    var timestamp: Date = Date()
    var type: NotificationType
    var subjectName: String?
    var wasDelivered: Bool = false
    var wasInteracted: Bool = false
    var deliveryDelay: TimeInterval = 0
    
    enum NotificationType: String, Codable {
        case lessonReminder = "Promemoria Lezione"
        case dailyNotification = "Notifica Giornaliera"
        case customReminder = "Promemoria Personalizzato"
        case smartSuggestion = "Suggerimento Intelligente"
    }
}

/// Metriche delle performance
struct NotificationMetrics: Codable {
    var totalNotificationsSent: Int = 0
    var notificationsDelivered: Int = 0
    var notificationsInteracted: Int = 0
    var averageDeliveryTime: TimeInterval = 0
    var subjectEngagement: [String: Double] = [:]
    var dailyPatterns: [String: Int] = [:]
    
    var deliveryRate: Double {
        guard totalNotificationsSent > 0 else { return 0 }
        return Double(notificationsDelivered) / Double(totalNotificationsSent)
    }
    
    var engagementRate: Double {
        guard notificationsDelivered > 0 else { return 0 }
        return Double(notificationsInteracted) / Double(notificationsDelivered)
    }
}

// MARK: - Estensioni di utilità

extension NotificationSettings {
    /// Ottiene la configurazione per una specifica materia
    func configForSubject(_ subject: String) -> SubjectNotificationConfig? {
        return subjectConfigs.first { $0.subjectName == subject }
    }
    
    /// Ottiene il programma per un giorno specifico
    func scheduleForDay(_ day: DaySchedule.DayOfWeek) -> DaySchedule? {
        return daySchedules.first { $0.dayOfWeek == day }
    }
    
    /// Verifica se le notifiche sono attive per un dato momento
    func areNotificationsActiveAt(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // Trova il programma del giorno
        let dayOfWeek = DaySchedule.DayOfWeek.allCases.first { 
            $0.weekdayComponent == weekday 
        }
        
        guard let dayOfWeek = dayOfWeek,
              let daySchedule = scheduleForDay(dayOfWeek),
              daySchedule.isEnabled else {
            return false
        }
        
        // Verifica ore di silenzio
        if let quietHours = daySchedule.quietHours ?? (globalQuietHours.isEnabled ? globalQuietHours : nil) {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
            let currentTime = calendar.date(from: timeComponents) ?? date
            
            if isTimeInQuietHours(currentTime, quietHours: quietHours) {
                return false
            }
        }
        
        return true
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
            // Stesso giorno (es. 22:00 - 23:00)
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            // Attraverso mezzanotte (es. 22:00 - 07:00)
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }
}