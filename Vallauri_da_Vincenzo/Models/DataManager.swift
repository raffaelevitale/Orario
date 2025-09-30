import Foundation
import SwiftUI
import Combine
import UserNotifications
import WidgetKit
import ActivityKit

// MARK: - Live Activity Attributes
struct ScheduleWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let currentLesson: String
        let teacher: String
        let classroom: String
        let startTime: String
        let endTime: String
        let progress: Double
        let remainingMinutes: Int
        let color: String
    }
    
    let lessonTitle: String
    let totalDuration: Int
}

class DataManager: ObservableObject {
    @Published var lessons: [Lesson] = []
    @Published var grades: [Grade] = []
    
    private let lessonsKey = "SavedLessons"
    private let gradesKey = "SavedGrades"
    
    init() {
        loadLessons()
        loadGrades()
        
        if lessons.isEmpty {
            // Combina lezioni e intervalli, poi ordina per giorno e orario
            lessons = (Lesson.sampleData + Lesson.breaks).sorted { first, second in
                if first.dayOfWeek == second.dayOfWeek {
                    return first.startTime < second.startTime
                } else {
                    return first.dayOfWeek < second.dayOfWeek
                }
            }
            // Salva i dati iniziali per il widget
            saveLessons()
        }
        
        // Programma le notifiche quando vengono caricate le lezioni
        scheduleNotificationsIfNeeded()
    }
    
    // MARK: - Persistence
    
    func saveData() {
        saveLessons()
        saveGrades()
    }
    
    func loadData() {
        loadLessons()
        loadGrades()
    }
    
    private func saveLessons() {
        if let encoded = try? JSONEncoder().encode(lessons) {
            UserDefaults.standard.set(encoded, forKey: lessonsKey)
            
            // Salva anche per il widget (App Group)
            if let sharedDefaults = UserDefaults(suiteName: "group.vallauri.schedule") {
                // Converte le lezioni in formato widget
                let widgetLessons = lessons.map { lesson in
                    WidgetLesson(
                        id: lesson.id.uuidString,
                        subject: lesson.subject,
                        teacher: lesson.teacher,
                        classroom: lesson.classroom,
                        dayOfWeek: lesson.dayOfWeek,
                        startTime: lesson.startTime,
                        endTime: lesson.endTime,
                        color: lesson.color
                    )
                }
                
                if let widgetEncoded = try? JSONEncoder().encode(widgetLessons) {
                    sharedDefaults.set(widgetEncoded, forKey: lessonsKey)
                    print("✅ Dati salvati con successo nell'App Group")
                    
                    // Notifica il widget che i dati sono cambiati
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } else {
                print("⚠️ App Group 'group.vallauri.schedule' non disponibile")
                print("📝 Configura l'App Group nel tuo Apple Developer Account")
                print("🔧 Assicurati che tutti i target abbiano l'entitlement corretto")
            }
        }
    }
    
    // Struttura per il widget
    private struct WidgetLesson: Codable {
        let id: String
        let subject: String
        let teacher: String
        let classroom: String
        let dayOfWeek: Int
        let startTime: String
        let endTime: String
        let color: String
    }
    
    private func loadLessons() {
        if let data = UserDefaults.standard.data(forKey: lessonsKey),
           let decoded = try? JSONDecoder().decode([Lesson].self, from: data) {
            lessons = decoded
        }
    }
    
    // MARK: - Grades Management
    
    private func saveGrades() {
        if let encoded = try? JSONEncoder().encode(grades) {
            UserDefaults.standard.set(encoded, forKey: gradesKey)
        }
    }
    
    private func loadGrades() {
        if let data = UserDefaults.standard.data(forKey: gradesKey),
           let decoded = try? JSONDecoder().decode([Grade].self, from: data) {
            grades = decoded
        }
    }
    
    func addGrade(_ grade: Grade) {
        grades.append(grade)
        saveGrades()
        forceWidgetUpdate() // Aggiorna i widget quando cambia un voto
    }
    
    func deleteGrade(_ grade: Grade) {
        grades.removeAll { $0.id == grade.id }
        saveGrades()
        forceWidgetUpdate() // Aggiorna i widget quando si cancella un voto
    }
    
    func updateGrade(_ grade: Grade) {
        if let index = grades.firstIndex(where: { $0.id == grade.id }) {
            grades[index] = grade
            saveGrades()
            forceWidgetUpdate() // Aggiorna i widget quando si modifica un voto
        }
    }
    
    // Ottiene le materie uniche dalle lezioni (escludendo gli intervalli)
    func getAvailableSubjects() -> [String] {
        let subjects = Set(lessons.compactMap { lesson in
            lesson.subject != "Intervallo" ? lesson.subject : nil
        })
        return Array(subjects).sorted()
    }
    
    // Ottiene il professore per una materia
    func getTeacherFor(subject: String) -> String {
        return lessons.first { $0.subject == subject }?.teacher ?? ""
    }
    
    // Ottiene il colore per una materia
    func getColorFor(subject: String) -> String {
        return lessons.first { $0.subject == subject }?.color ?? "#9e9e9e"
    }
    
    // Raggruppa i voti per materia
    func getGradesGroupedBySubject() -> [SubjectGrades] {
        let subjects = getAvailableSubjects()
        return subjects.compactMap { subject in
            let subjectGrades = grades.filter { $0.subject == subject }
            guard !subjectGrades.isEmpty else { return nil }
            
            return SubjectGrades(
                subject: subject,
                color: getColorFor(subject: subject),
                teacher: getTeacherFor(subject: subject),
                grades: subjectGrades.sorted { $0.date > $1.date }
            )
        }.sorted { $0.subject < $1.subject }
    }
    
    // Calcola la media generale di tutti i voti
    var overallAverage: Double {
        guard !grades.isEmpty else { return 0.0 }
        return grades.reduce(0) { $0 + $1.value } / Double(grades.count)
    }
    
    // MARK: - Notifications Management
    
    private func scheduleNotificationsIfNeeded() {
        // Verifica se i permessi sono stati concessi
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    // Includi TUTTE le lezioni e gli intervalli
                    print("🔔 Programmazione notifiche per \(self.lessons.count) lezioni e intervalli...")
                    NotificationManager.shared.scheduleNotifications(for: self.lessons)
                }
            } else {
                print("⚠️ Permessi notifiche non concessi, non programmo le notifiche")
            }
        }
    }
    
    // Metodo per riprogrammare le notifiche manualmente
    func rescheduleNotifications() {
        print("🔄 Riprogrammazione notifiche...")
        // Programma notifiche per TUTTE le lezioni e intervalli
        NotificationManager.shared.scheduleNotifications(for: lessons)
    }
    
    // Richiedi permessi e programma notifiche
    func setupNotifications() {
        NotificationManager.shared.requestPermissions { [weak self] granted in
            if granted {
                self?.rescheduleNotifications()
                print("✅ Notifiche programmate!")
            } else {
                print("❌ Permessi negati!")
            }
        }
    }
    
    // MARK: - Live Activities Management
    
    func startLiveActivityForCurrentLesson() {
        // Per le Live Activities escludiamo gli intervalli
        let todayLessons = getTodaysLessons().filter { $0.subject != "Intervallo" }
        let calendar = Calendar.current
        let now = Date()
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        
        for lesson in todayLessons {
            if let startMinutes = timeToMinutes(lesson.startTime),
               let endMinutes = timeToMinutes(lesson.endTime),
               currentMinutes >= startMinutes && currentMinutes < endMinutes {
                
                let totalDuration = endMinutes - startMinutes
                let elapsed = currentMinutes - startMinutes
                let remaining = endMinutes - currentMinutes
                let progress = Double(elapsed) / Double(totalDuration)
                
                let attributes = ScheduleWidgetAttributes(
                    lessonTitle: lesson.subject,
                    totalDuration: totalDuration
                )
                
                let contentState = ScheduleWidgetAttributes.ContentState(
                    currentLesson: lesson.subject,
                    teacher: lesson.teacher,
                    classroom: lesson.classroom,
                    startTime: lesson.startTime,
                    endTime: lesson.endTime,
                    progress: progress,
                    remainingMinutes: remaining,
                    color: lesson.color
                )
                
                do {
                    let activity = try Activity<ScheduleWidgetAttributes>.request(
                        attributes: attributes,
                        contentState: contentState,
                        pushType: nil
                    )
                    print("✅ Live Activity avviata: \(activity.id)")
                } catch {
                    print("❌ Errore Live Activity: \(error)")
                }
                
                break
            }
        }
    }
    
    func updateLiveActivity() {
        // Aggiorna tutte le Live Activities attive
        for activity in Activity<ScheduleWidgetAttributes>.activities {
            let todayLessons = getTodaysLessons().filter { $0.subject != "Intervallo" }
            let calendar = Calendar.current
            let now = Date()
            let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
            
            for lesson in todayLessons {
                if lesson.subject == activity.attributes.lessonTitle,
                   let startMinutes = timeToMinutes(lesson.startTime),
                   let endMinutes = timeToMinutes(lesson.endTime),
                   currentMinutes >= startMinutes && currentMinutes < endMinutes {
                    
                    let totalDuration = endMinutes - startMinutes
                    let elapsed = currentMinutes - startMinutes
                    let remaining = endMinutes - currentMinutes
                    let progress = Double(elapsed) / Double(totalDuration)
                    
                    let contentState = ScheduleWidgetAttributes.ContentState(
                        currentLesson: lesson.subject,
                        teacher: lesson.teacher,
                        classroom: lesson.classroom,
                        startTime: lesson.startTime,
                        endTime: lesson.endTime,
                        progress: progress,
                        remainingMinutes: remaining,
                        color: lesson.color
                    )
                    
                    Task {
                        await activity.update(using: contentState)
                    }
                }
            }
        }
    }
    
    func endLiveActivity() {
        for activity in Activity<ScheduleWidgetAttributes>.activities {
            Task {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
    
    private func timeToMinutes(_ time: String) -> Int? {
        let components = time.components(separatedBy: ":")
        guard components.count == 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else { return nil }
        return hours * 60 + minutes
    }
    
    // MARK: - Widget Management
    
    func forceWidgetUpdate() {
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 Widget timeline aggiornata")
    }
    
    // MARK: - Auto Live Activities Management
    
    func checkAndManageLiveActivities() {
        let calendar = Calendar.current
        let now = Date()
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentDayOfWeek = currentWeekday == 1 ? 7 : currentWeekday - 1
        
        let todayLessons = lessons.filter { 
            $0.dayOfWeek == currentDayOfWeek && $0.subject != "Intervallo" 
        }
        
        var hasCurrentLesson = false
        
        // Controlla se c'è una lezione in corso
        for lesson in todayLessons {
            if let startMinutes = timeToMinutes(lesson.startTime),
               let endMinutes = timeToMinutes(lesson.endTime),
               currentMinutes >= startMinutes && currentMinutes < endMinutes {
                
                hasCurrentLesson = true
                
                // Controlla se c'è già una Live Activity per questa lezione
                let existingActivity = Activity<ScheduleWidgetAttributes>.activities.first {
                    $0.attributes.lessonTitle == lesson.subject
                }
                
                if existingActivity == nil {
                    // Avvia nuova Live Activity
                    startLiveActivityForLesson(lesson)
                } else {
                    // Aggiorna quella esistente
                    updateLiveActivityForLesson(lesson)
                }
                break
            }
        }
        
        // Se non c'è una lezione in corso, termina tutte le Live Activities
        if !hasCurrentLesson {
            endAllLiveActivities()
        }
    }
    
    private func startLiveActivityForLesson(_ lesson: Lesson) {
        let calendar = Calendar.current
        let now = Date()
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        
        guard let startMinutes = timeToMinutes(lesson.startTime),
              let endMinutes = timeToMinutes(lesson.endTime) else { return }
        
        let totalDuration = endMinutes - startMinutes
        let elapsed = currentMinutes - startMinutes
        let remaining = endMinutes - currentMinutes
        let progress = Double(elapsed) / Double(totalDuration)
        
        let attributes = ScheduleWidgetAttributes(
            lessonTitle: lesson.subject,
            totalDuration: totalDuration
        )
        
        let contentState = ScheduleWidgetAttributes.ContentState(
            currentLesson: lesson.subject,
            teacher: lesson.teacher,
            classroom: lesson.classroom,
            startTime: lesson.startTime,
            endTime: lesson.endTime,
            progress: progress,
            remainingMinutes: remaining,
            color: lesson.color
        )
        
        do {
            let activity = try Activity<ScheduleWidgetAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            print("✅ Live Activity avviata per: \(lesson.subject)")
        } catch {
            print("❌ Errore avvio Live Activity: \(error)")
        }
    }
    
    private func updateLiveActivityForLesson(_ lesson: Lesson) {
        let calendar = Calendar.current
        let now = Date()
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        
        guard let startMinutes = timeToMinutes(lesson.startTime),
              let endMinutes = timeToMinutes(lesson.endTime) else { return }
        
        let totalDuration = endMinutes - startMinutes
        let elapsed = currentMinutes - startMinutes
        let remaining = endMinutes - currentMinutes
        let progress = Double(elapsed) / Double(totalDuration)
        
        let contentState = ScheduleWidgetAttributes.ContentState(
            currentLesson: lesson.subject,
            teacher: lesson.teacher,
            classroom: lesson.classroom,
            startTime: lesson.startTime,
            endTime: lesson.endTime,
            progress: progress,
            remainingMinutes: remaining,
            color: lesson.color
        )
        
        Task {
            for activity in Activity<ScheduleWidgetAttributes>.activities {
                if activity.attributes.lessonTitle == lesson.subject {
                    await activity.update(using: contentState)
                    print("🔄 Live Activity aggiornata per: \(lesson.subject)")
                }
            }
        }
    }
    
    private func endAllLiveActivities() {
        Task {
            for activity in Activity<ScheduleWidgetAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
                print("⏹ Live Activity terminata per: \(activity.attributes.lessonTitle)")
            }
        }
    }
    
    // MARK: - Lessons for specific day
    
    func getLessonsForDay(_ dayOfWeek: Int) -> [Lesson] {
        return lessons
            .filter { $0.dayOfWeek == dayOfWeek }
            .sorted { $0.startTime < $1.startTime }
    }
    
    func getTodaysLessons() -> [Lesson] {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        // Convert from Sunday=1 system to Monday=1 system
        let dayOfWeek = today == 1 ? 7 : today - 1
        return getLessonsForDay(dayOfWeek)
    }
    
    // MARK: - Current Lesson Detection
    
    func getCurrentLesson() -> Lesson? {
        let calendar = Calendar.current
        let now = Date()
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentDayOfWeek = currentWeekday == 1 ? 7 : currentWeekday - 1
        
        let todayLessons = lessons.filter { $0.dayOfWeek == currentDayOfWeek }
        
        for lesson in todayLessons {
            if let startMinutes = timeToMinutes(lesson.startTime),
               let endMinutes = timeToMinutes(lesson.endTime),
               currentMinutes >= startMinutes && currentMinutes < endMinutes {
                return lesson
            }
        }
        return nil
    }
    
    func getNextLesson() -> Lesson? {
        let calendar = Calendar.current
        let now = Date()
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentDayOfWeek = currentWeekday == 1 ? 7 : currentWeekday - 1
        
        let todayLessons = lessons.filter { $0.dayOfWeek == currentDayOfWeek }
            .sorted { $0.startTime < $1.startTime }
        
        for lesson in todayLessons {
            if let startMinutes = timeToMinutes(lesson.startTime),
               currentMinutes < startMinutes {
                return lesson
            }
        }
        return nil
    }
    
    func isCurrentLesson(_ lesson: Lesson) -> Bool {
        return getCurrentLesson()?.id == lesson.id
    }
    
    func isNextLesson(_ lesson: Lesson) -> Bool {
        return getNextLesson()?.id == lesson.id
    }
}