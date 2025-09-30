//
//  StudyTimer.swift
//  Vallauri_da_Vincenzo
//

import Foundation
import SwiftUI
import UserNotifications
import AVFoundation
import Combine

// MARK: - Timer States

enum TimerState: String, CaseIterable {
    case idle = "Fermo"
    case running = "In corso"
    case paused = "In pausa"
    case shortBreak = "Pausa"
    case longBreak = "Pausa lunga"
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .running: return .green
        case .paused: return .orange
        case .shortBreak: return .blue
        case .longBreak: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "pause.circle"
        case .running: return "play.circle.fill"
        case .paused: return "pause.circle.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "bed.double.fill"
        }
    }
}

enum TimerType: String, CaseIterable, Codable {
    case pomodoro = "Pomodoro"
    case custom = "Personalizzato"
    
    var defaultDuration: Int {
        switch self {
        case .pomodoro: return 25 * 60 // 25 minutes
        case .custom: return 30 * 60 // 30 minutes
        }
    }
    
    var shortBreakDuration: Int {
        switch self {
        case .pomodoro: return 5 * 60 // 5 minutes
        case .custom: return 10 * 60 // 10 minutes
        }
    }
    
    var longBreakDuration: Int {
        switch self {
        case .pomodoro: return 15 * 60 // 15 minutes
        case .custom: return 20 * 60 // 20 minutes
        }
    }
}

// MARK: - Study Session Models

struct StudySession: Identifiable, Codable {
    let id: UUID
    let subject: String
    let startTime: Date
    let endTime: Date
    let duration: Int // in seconds
    let type: TimerType
    let pomodoroCount: Int
    let isCompleted: Bool
    let notes: String
    
    init(id: UUID = UUID(), subject: String, startTime: Date, endTime: Date, duration: Int, type: TimerType, pomodoroCount: Int, isCompleted: Bool, notes: String) {
        self.id = id
        self.subject = subject
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.type = type
        self.pomodoroCount = pomodoroCount
        self.isCompleted = isCompleted
        self.notes = notes
    }
    
    var formattedDuration: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isToday(startTime) {
            formatter.timeStyle = .short
            return "Oggi alle \(formatter.string(from: startTime))"
        } else if calendar.isYesterday(startTime) {
            formatter.timeStyle = .short
            return "Ieri alle \(formatter.string(from: startTime))"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: startTime)
        }
    }
}

struct DailyStats: Identifiable {
    let id = UUID()
    let date: Date
    let totalStudyTime: Int // in seconds
    let completedSessions: Int
    let totalSessions: Int
    let subjectBreakdown: [String: Int] // subject -> time in seconds
    
    var efficiency: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions)
    }
    
    var formattedStudyTime: String {
        let hours = totalStudyTime / 3600
        let minutes = (totalStudyTime % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}

// MARK: - Study Timer Manager

class StudyTimerManager: ObservableObject {
    @Published var currentState: TimerState = .idle
    @Published var remainingTime: Int = 0
    @Published var selectedSubject: String = ""
    @Published var selectedType: TimerType = .pomodoro
    @Published var pomodoroCount: Int = 0
    @Published var currentSessionStartTime: Date?
    @Published var sessions: [StudySession] = []
    @Published var isNotificationEnabled: Bool = true
    @Published var isSoundEnabled: Bool = true
    @Published var customDuration: Int = 30 * 60 // 30 minutes default
    
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private let sessionsKey = "StudySessions"
    private let settingsKey = "StudyTimerSettings"
    
    // Settings
    @Published var pomodoroSession: Int = 25 * 60
    @Published var shortBreak: Int = 5 * 60
    @Published var longBreak: Int = 15 * 60
    @Published var longBreakInterval: Int = 4 // Every 4 pomodoros
    
    init() {
        loadSessions()
        loadSettings()
        setupAudioSession()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Timer Control
    
    func startTimer(subject: String, type: TimerType) {
        selectedSubject = subject
        selectedType = type
        currentSessionStartTime = Date()
        
        switch type {
        case .pomodoro:
            remainingTime = pomodoroSession
        case .custom:
            remainingTime = customDuration
        }
        
        currentState = .running
        startCountdown()
    }
    
    func pauseTimer() {
        timer?.invalidate()
        currentState = .paused
    }
    
    func resumeTimer() {
        currentState = .running
        startCountdown()
    }
    
    func stopTimer(completed: Bool = false) {
        timer?.invalidate()
        
        if let startTime = currentSessionStartTime, currentState != .idle {
            let duration = selectedType == .pomodoro ? 
                pomodoroSession - remainingTime : 
                customDuration - remainingTime
            
            if duration > 30 { // Only save sessions longer than 30 seconds
                let session = StudySession(
                    subject: selectedSubject,
                    startTime: startTime,
                    endTime: Date(),
                    duration: duration,
                    type: selectedType,
                    pomodoroCount: pomodoroCount + (completed ? 1 : 0),
                    isCompleted: completed,
                    notes: ""
                )
                
                addSession(session)
            }
        }
        
        if completed {
            handleSessionCompletion()
        }
        
        resetTimer()
    }
    
    func resetTimer() {
        timer?.invalidate()
        currentState = .idle
        remainingTime = 0
        currentSessionStartTime = nil
        selectedSubject = ""
    }
    
    private func startCountdown() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        if remainingTime > 0 {
            remainingTime -= 1
        } else {
            stopTimer(completed: true)
        }
    }
    
    private func handleSessionCompletion() {
        if selectedType == .pomodoro {
            pomodoroCount += 1
            
            // Determine break type
            if pomodoroCount % longBreakInterval == 0 {
                startBreak(isLong: true)
            } else {
                startBreak(isLong: false)
            }
        }
        
        playCompletionSound()
        sendCompletionNotification()
    }
    
    private func startBreak(isLong: Bool) {
        currentState = isLong ? .longBreak : .shortBreak
        remainingTime = isLong ? longBreak : shortBreak
        currentSessionStartTime = Date()
        startCountdown()
    }
    
    // MARK: - Session Management
    
    private func addSession(_ session: StudySession) {
        sessions.insert(session, at: 0)
        saveSessions()
    }
    
    func deleteSession(_ session: StudySession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([StudySession].self, from: data) {
            sessions = decoded
        }
    }
    
    private func saveSettings() {
        let settings = [
            "pomodoroSession": pomodoroSession,
            "shortBreak": shortBreak,
            "longBreak": longBreak,
            "longBreakInterval": longBreakInterval,
            "customDuration": customDuration,
            "isNotificationEnabled": isNotificationEnabled,
            "isSoundEnabled": isSoundEnabled
        ] as [String : Any]
        
        UserDefaults.standard.set(settings, forKey: settingsKey)
    }
    
    private func loadSettings() {
        if let settings = UserDefaults.standard.dictionary(forKey: settingsKey) {
            pomodoroSession = settings["pomodoroSession"] as? Int ?? 25 * 60
            shortBreak = settings["shortBreak"] as? Int ?? 5 * 60
            longBreak = settings["longBreak"] as? Int ?? 15 * 60
            longBreakInterval = settings["longBreakInterval"] as? Int ?? 4
            customDuration = settings["customDuration"] as? Int ?? 30 * 60
            isNotificationEnabled = settings["isNotificationEnabled"] as? Bool ?? true
            isSoundEnabled = settings["isSoundEnabled"] as? Bool ?? true
        }
    }
    
    func updateSettings(
        pomodoroSession: Int,
        shortBreak: Int,
        longBreak: Int,
        longBreakInterval: Int,
        customDuration: Int,
        isNotificationEnabled: Bool,
        isSoundEnabled: Bool
    ) {
        self.pomodoroSession = pomodoroSession
        self.shortBreak = shortBreak
        self.longBreak = longBreak
        self.longBreakInterval = longBreakInterval
        self.customDuration = customDuration
        self.isNotificationEnabled = isNotificationEnabled
        self.isSoundEnabled = isSoundEnabled
        
        saveSettings()
    }
    
    // MARK: - Statistics
    
    func getSessionsForDate(_ date: Date) -> [StudySession] {
        let calendar = Calendar.current
        return sessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: date)
        }
    }
    
    func getDailyStats(for date: Date) -> DailyStats {
        let daySessions = getSessionsForDate(date)
        let totalTime = daySessions.reduce(0) { $0 + $1.duration }
        let completedSessions = daySessions.filter { $0.isCompleted }.count
        
        var subjectBreakdown: [String: Int] = [:]
        for session in daySessions {
            subjectBreakdown[session.subject, default: 0] += session.duration
        }
        
        return DailyStats(
            date: date,
            totalStudyTime: totalTime,
            completedSessions: completedSessions,
            totalSessions: daySessions.count,
            subjectBreakdown: subjectBreakdown
        )
    }
    
    func getWeeklyStats() -> [DailyStats] {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                return nil
            }
            return getDailyStats(for: date)
        }
    }
    
    func getTotalStudyTimeThisWeek() -> Int {
        return getWeeklyStats().reduce(0) { $0 + $1.totalStudyTime }
    }
    
    func getSubjectStats() -> [String: (totalTime: Int, sessions: Int)] {
        var stats: [String: (totalTime: Int, sessions: Int)] = [:]
        
        for session in sessions {
            let current = stats[session.subject] ?? (totalTime: 0, sessions: 0)
            stats[session.subject] = (
                totalTime: current.totalTime + session.duration,
                sessions: current.sessions + 1
            )
        }
        
        return stats
    }
    
    func getTopSubjects(limit: Int = 5) -> [(subject: String, time: Int)] {
        let subjectStats = getSubjectStats()
        return subjectStats
            .map { (subject: $0.key, time: $0.value.totalTime) }
            .sorted { $0.time > $1.time }
            .prefix(limit)
            .map { $0 }
    }
    
    func getStreakDays() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let dayStats = getDailyStats(for: currentDate)
            if dayStats.totalStudyTime > 0 {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    var averageSessionDuration: Int {
        guard !sessions.isEmpty else { return 0 }
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        return totalDuration / sessions.count
    }
    
    var totalStudyTime: Int {
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    var totalSessions: Int {
        sessions.count
    }
    
    var completedSessions: Int {
        sessions.filter { $0.isCompleted }.count
    }
    
    var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions)
    }
    
    // MARK: - Notifications and Audio
    
    private func sendCompletionNotification() {
        guard isNotificationEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Sessione di studio completata!"
        
        switch currentState {
        case .shortBreak:
            content.body = "Pausa di \(shortBreak / 60) minuti iniziata"
        case .longBreak:
            content.body = "Pausa lunga di \(longBreak / 60) minuti iniziata"
        default:
            content.body = "Ottimo lavoro! \(selectedSubject) - \(selectedType.rawValue)"
        }
        
        content.sound = isSoundEnabled ? .default : nil
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \\(error)")
        }
    }
    
    private func playCompletionSound() {
        guard isSoundEnabled else { return }
        
        // Play system sound
        AudioServicesPlaySystemSound(1007) // Success sound
    }
    
    // MARK: - Formatting Helpers
    
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    func getProgressPercentage() -> Double {
        let totalDuration = selectedType == .pomodoro ? pomodoroSession : customDuration
        guard totalDuration > 0 else { return 0 }
        return Double(totalDuration - remainingTime) / Double(totalDuration)
    }
}

// MARK: - Audio Services Import

import AudioToolbox
