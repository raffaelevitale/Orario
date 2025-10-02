//
//  WeeklyPlanner.swift
//  Vallauri_da_Vincenzo
//

import Foundation
import SwiftUI
import Combine

// MARK: - Task Models

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Bassa"
    case medium = "Media"
    case high = "Alta"
    case urgent = "Urgente"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "chevron.down"
        case .medium: return "minus"
        case .high: return "chevron.up"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}

enum TaskType: String, CaseIterable, Codable {
    case homework = "Compito"
    case study = "Studio"
    case exam = "Verifica"
    case project = "Progetto"
    case reading = "Lettura"
    case exercise = "Esercizi"
    case other = "Altro"
    
    var icon: String {
        switch self {
        case .homework: return "book.fill"
        case .study: return "brain.head.profile"
        case .exam: return "doc.text"
        case .project: return "folder.fill"
        case .reading: return "text.book.closed"
        case .exercise: return "pencil"
        case .other: return "ellipsis.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .homework: return .blue
        case .study: return .purple
        case .exam: return .red
        case .project: return .orange
        case .reading: return .green
        case .exercise: return .yellow
        case .other: return .gray
        }
    }
}

struct PlannerTask: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var subject: String
    var type: TaskType
    var priority: TaskPriority
    var dueDate: Date
    var estimatedDuration: Int // in minutes
    var isCompleted: Bool
    var completedDate: Date?
    var createdDate: Date
    var tags: [String]
    
    init(
        title: String,
        description: String = "",
        subject: String,
        type: TaskType = .homework,
        priority: TaskPriority = .medium,
        dueDate: Date,
        estimatedDuration: Int = 60,
        tags: [String] = []
    ) {
        self.title = title
        self.description = description
        self.subject = subject
        self.type = type
        self.priority = priority
        self.dueDate = dueDate
        self.estimatedDuration = estimatedDuration
        self.isCompleted = false
        self.completedDate = nil
        self.createdDate = Date()
        self.tags = tags
    }
    
    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }
    
    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
    
    var dueDateFormatted: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(dueDate) {
            return "Oggi"
        } else if calendar.isDateInTomorrow(dueDate) {
            return "Domani"
        } else if calendar.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.locale = Locale(identifier: "it_IT")
            formatter.dateFormat = "EEEE"
            return formatter.string(from: dueDate)
        } else {
            formatter.dateFormat = "dd/MM"
            return formatter.string(from: dueDate)
        }
    }
}

// MARK: - Weekly Planner Manager

class WeeklyPlannerManager: ObservableObject {
    @Published var tasks: [PlannerTask] = []
    @Published var selectedWeekOffset: Int = 0 // 0 = current week, 1 = next week, etc.
    
    private let tasksKey = "WeeklyPlannerTasks"
    
    init() {
        loadTasks()
    }
    
    // MARK: - Persistence
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([PlannerTask].self, from: data) {
            tasks = decoded
        }
    }
    
    // MARK: - Task Management
    
    func addTask(_ task: PlannerTask) {
        tasks.append(task)
        saveTasks()
    }
    
    func updateTask(_ task: PlannerTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func deleteTask(_ task: PlannerTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: PlannerTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            tasks[index].completedDate = tasks[index].isCompleted ? Date() : nil
            saveTasks()
        }
    }
    
    // MARK: - Filtering and Sorting
    
    func getTasksForWeek(offset: Int = 0) -> [PlannerTask] {
        let calendar = Calendar.current
        let today = Date()
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start,
              let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: weekStart),
              let targetWeekEnd = calendar.date(byAdding: .day, value: 6, to: targetWeekStart) else {
            return []
        }
        
        return tasks.filter { task in
            task.dueDate >= targetWeekStart && task.dueDate <= targetWeekEnd
        }.sorted { task1, task2 in
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted // Non completati prima
            }
            if task1.priority != task2.priority {
                return task1.priority.rawValue > task2.priority.rawValue // Priorità alta prima
            }
            return task1.dueDate < task2.dueDate // Data di scadenza più vicina prima
        }
    }
    
    func getTasksForDay(_ date: Date) -> [PlannerTask] {
        let calendar = Calendar.current
        return tasks.filter { task in
            calendar.isDate(task.dueDate, inSameDayAs: date)
        }.sorted { task1, task2 in
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted
            }
            if task1.priority != task2.priority {
                return task1.priority.rawValue > task2.priority.rawValue
            }
            return task1.dueDate < task2.dueDate
        }
    }
    
    func getTasksBySubject() -> [String: [PlannerTask]] {
        Dictionary(grouping: tasks) { $0.subject }
    }
    
    func getOverdueTasks() -> [PlannerTask] {
        tasks.filter { $0.isOverdue }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    func getCompletedTasks() -> [PlannerTask] {
        tasks.filter { $0.isCompleted }
            .sorted { $0.completedDate ?? Date.distantPast > $1.completedDate ?? Date.distantPast }
    }
    
    func getTasksByPriority(_ priority: TaskPriority) -> [PlannerTask] {
        tasks.filter { $0.priority == priority && !$0.isCompleted }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    // MARK: - Statistics
    
    var totalTasks: Int { tasks.count }
    
    var completedTasks: Int { tasks.filter { $0.isCompleted }.count }
    
    var pendingTasks: Int { tasks.filter { !$0.isCompleted }.count }
    
    var overdueTasks: Int { tasks.filter { $0.isOverdue }.count }
    
    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    func getTasksCountForWeek(_ weekOffset: Int = 0) -> (total: Int, completed: Int, pending: Int, overdue: Int) {
        let weekTasks = getTasksForWeek(offset: weekOffset)
        let completed = weekTasks.filter { $0.isCompleted }.count
        let pending = weekTasks.filter { !$0.isCompleted && !$0.isOverdue }.count
        let overdue = weekTasks.filter { $0.isOverdue }.count
        
        return (total: weekTasks.count, completed: completed, pending: pending, overdue: overdue)
    }
    
    func getEstimatedTimeForWeek(_ weekOffset: Int = 0) -> Int {
        return getTasksForWeek(offset: weekOffset)
            .filter { !$0.isCompleted }
            .reduce(0) { $0 + $1.estimatedDuration }
    }
    
    // MARK: - Week Navigation
    
    func getCurrentWeekDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start,
              let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: selectedWeekOffset, to: weekStart) else {
            return []
        }
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: targetWeekStart)
        }
    }
    
    func getWeekTitle() -> String {
        let calendar = Calendar.current
        let today = Date()
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start,
              let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: selectedWeekOffset, to: weekStart),
              let targetWeekEnd = calendar.date(byAdding: .day, value: 6, to: targetWeekStart) else {
            return "Settimana"
        }
        
        let formatter = DateFormatter()
        
        if selectedWeekOffset == 0 {
            return "Questa settimana"
        } else if selectedWeekOffset == 1 {
            return "Prossima settimana"
        } else if selectedWeekOffset == -1 {
            return "Settimana scorsa"
        } else {
            formatter.dateFormat = "dd MMM"
            let startString = formatter.string(from: targetWeekStart)
            let endString = formatter.string(from: targetWeekEnd)
            return "\(startString) - \(endString)"
        }
    }
}

