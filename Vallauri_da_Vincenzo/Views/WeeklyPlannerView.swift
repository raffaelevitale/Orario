//
//  WeeklyPlannerView.swift
//  Vallauri_da_Vincenzo
//

import SwiftUI

struct WeeklyPlannerView: View {
    @StateObject private var plannerManager = WeeklyPlannerManager()
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedDate = Date()
    @State private var showingAddTask = false
    @State private var showingTaskDetail: PlannerTask?
    @State private var viewMode: ViewMode = .week
    
    enum ViewMode: String, CaseIterable {
        case week = "Settimana"
        case day = "Giorno"
        case list = "Lista"
        
        var icon: String {
            switch self {
            case .week: return "calendar"
            case .day: return "calendar.day.timeline.left"
            case .list: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: settingsManager.backgroundColor.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with stats
                    headerView
                    
                    // View mode selector
                    viewModeSelector
                    
                    // Content based on view mode
                    switch viewMode {
                    case .week:
                        weekView
                    case .day:
                        dayView
                    case .list:
                        listView
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Planner")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(plannerManager: plannerManager, dataManager: dataManager)
            }
            .sheet(item: $showingTaskDetail) { task in
                TaskDetailView(task: task, plannerManager: plannerManager)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Week navigation (only for week view)
            if viewMode == .week {
                HStack {
                    Button(action: { plannerManager.selectedWeekOffset -= 1 }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(plannerManager.getWeekTitle())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { plannerManager.selectedWeekOffset += 1 }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
            }
            
            // Stats cards
            let stats = plannerManager.getTasksCountForWeek(plannerManager.selectedWeekOffset)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Totali", 
                    value: "\(stats.total)", 
                    color: .blue,
                    icon: "doc.text"
                )
                StatCard(
                    title: "Completati", 
                    value: "\(stats.completed)", 
                    color: .green,
                    icon: "checkmark.circle"
                )
                StatCard(
                    title: "In attesa", 
                    value: "\(stats.pending)", 
                    color: .orange,
                    icon: "clock"
                )
                StatCard(
                    title: "In ritardo", 
                    value: "\(stats.overdue)", 
                    color: .red,
                    icon: "exclamationmark.triangle"
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - View Mode Selector
    
    private var viewModeSelector: some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button(action: { 
                    withAnimation(.spring(response: 0.3)) {
                        viewMode = mode
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.caption)
                        Text(mode.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(viewMode == mode ? .black : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        viewMode == mode ? 
                            .white : 
                            Color.clear
                    )
                    .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Week View
    
    private var weekView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                let weekDates = plannerManager.getCurrentWeekDates()
                
                ForEach(weekDates, id: \.self) { date in
                    WeekDayCardView(
                        date: date,
                        tasks: plannerManager.getTasksForDay(date),
                        plannerManager: plannerManager,
                        onTaskTap: { task in
                            showingTaskDetail = task
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Day View
    
    private var dayView: some View {
        VStack(spacing: 0) {
            // Date picker
            DatePicker(
                "Seleziona data",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .padding(.horizontal)
            .padding(.bottom)
            
            // Tasks for selected date
            ScrollView {
                let dayTasks = plannerManager.getTasksForDay(selectedDate)
                
                if dayTasks.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.plus",
                        title: "Nessun compito",
                        subtitle: "Non ci sono compiti per questa data"
                    )
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(dayTasks) { task in
                            TaskCardView(
                                task: task,
                                plannerManager: plannerManager,
                                onTap: { showingTaskDetail = task }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    // MARK: - List View
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Overdue tasks
                if !plannerManager.getOverdueTasks().isEmpty {
                    TaskSectionView(
                        title: "In ritardo",
                        tasks: plannerManager.getOverdueTasks(),
                        color: .red,
                        plannerManager: plannerManager,
                        onTaskTap: { task in showingTaskDetail = task }
                    )
                }
                
                // Today's tasks
                let todayTasks = plannerManager.getTasksForDay(Date())
                    .filter { !$0.isOverdue }
                
                if !todayTasks.isEmpty {
                    TaskSectionView(
                        title: "Oggi",
                        tasks: todayTasks,
                        color: .blue,
                        plannerManager: plannerManager,
                        onTaskTap: { task in showingTaskDetail = task }
                    )
                }
                
                // Upcoming tasks by priority
                ForEach(TaskPriority.allCases.reversed(), id: \.self) { priority in
                    let priorityTasks = plannerManager.getTasksByPriority(priority)
                        .filter { !Calendar.current.isToday($0.dueDate) && !$0.isOverdue }
                    
                    if !priorityTasks.isEmpty {
                        TaskSectionView(
                            title: "Priorità \(priority.rawValue)",
                            tasks: priorityTasks,
                            color: priority.color,
                            plannerManager: plannerManager,
                            onTaskTap: { task in showingTaskDetail = task }
                        )
                    }
                }
                
                // Completed tasks
                if !plannerManager.getCompletedTasks().isEmpty {
                    TaskSectionView(
                        title: "Completati",
                        tasks: plannerManager.getCompletedTasks(),
                        color: .green,
                        plannerManager: plannerManager,
                        onTaskTap: { task in showingTaskDetail = task }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1)
        }
    }
}

struct WeekDayCardView: View {
    let date: Date
    let tasks: [PlannerTask]
    let plannerManager: WeeklyPlannerManager
    let onTaskTap: (PlannerTask) -> Void
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isToday(date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayFormatter.string(from: date))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isToday ? .blue : .white.opacity(0.8))
                    
                    Text(dateFormatter.string(from: date))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if !tasks.isEmpty {
                    HStack(spacing: 8) {
                        let completedCount = tasks.filter { $0.isCompleted }.count
                        let overdueCount = tasks.filter { $0.isOverdue }.count
                        
                        if overdueCount > 0 {
                            Badge(count: overdueCount, color: .red)
                        }
                        
                        Badge(count: completedCount, color: .green)
                        Badge(count: tasks.count - completedCount, color: .orange)
                    }
                }
            }
            
            // Tasks
            if tasks.isEmpty {
                Text("Nessun compito")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
                    .padding(.leading, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks.prefix(3)) { task in
                        CompactTaskView(task: task, plannerManager: plannerManager) {
                            onTaskTap(task)
                        }
                    }
                    
                    if tasks.count > 3 {
                        Button(action: {}) {
                            Text("Vedi altri \(tasks.count - 3) compiti")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isToday ? .blue.opacity(0.5) : .clear, lineWidth: 2)
        }
    }
}

struct Badge: View {
    let count: Int
    let color: Color
    
    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color)
                .clipShape(Capsule())
        }
    }
}

struct CompactTaskView: View {
    let task: PlannerTask
    let plannerManager: WeeklyPlannerManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Completion checkbox
                Button(action: {
                    plannerManager.toggleTaskCompletion(task)
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(task.isCompleted ? .green : .white.opacity(0.6))
                }
                
                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Image(systemName: task.type.icon)
                            .font(.caption2)
                        Text(task.subject)
                            .font(.caption2)
                        
                        Spacer()
                        
                        if task.isOverdue {
                            Text("In ritardo")
                                .font(.caption2)
                                .foregroundColor(.red)
                        } else {
                            Text(task.dueDateFormatted)
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Priority indicator
                Image(systemName: task.priority.icon)
                    .font(.caption)
                    .foregroundColor(task.priority.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(task.isCompleted ? .green.opacity(0.1) : .white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TaskSectionView: View {
    let title: String
    let tasks: [PlannerTask]
    let color: Color
    let plannerManager: WeeklyPlannerManager
    let onTaskTap: (PlannerTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color)
                    .clipShape(Capsule())
            }
            
            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    TaskCardView(
                        task: task,
                        plannerManager: plannerManager,
                        onTap: { onTaskTap(task) }
                    )
                }
            }
        }
    }
}

struct TaskCardView: View {
    let task: PlannerTask
    let plannerManager: WeeklyPlannerManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Type and priority indicator
                VStack(spacing: 6) {
                    Image(systemName: task.type.icon)
                        .font(.title3)
                        .foregroundColor(task.type.color)
                    
                    Image(systemName: task.priority.icon)
                        .font(.caption)
                        .foregroundColor(task.priority.color)
                }
                
                // Task details
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)
                    
                    Text(task.subject)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 12) {
                        Label(task.dueDateFormatted, systemImage: "calendar")
                        Label("\(task.estimatedDuration) min", systemImage: "clock")
                    }
                    .font(.caption2)
                    .foregroundColor(task.isOverdue ? .red : .white.opacity(0.7))
                }
                
                Spacer()
                
                // Completion checkbox
                Button(action: {
                    plannerManager.toggleTaskCompletion(task)
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.isCompleted ? .green : .white.opacity(0.6))
                }
            }
            .padding()
            .background {
                if task.isCompleted {
                    Color.green.opacity(0.1)
                } else if task.isOverdue {
                    Color.red.opacity(0.1)
                } else {
                    Rectangle().fill(.ultraThinMaterial)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        task.isCompleted ? .green.opacity(0.3) :
                        (task.isOverdue ? .red.opacity(0.3) : task.priority.color.opacity(0.3)),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    WeeklyPlannerView()
        .environmentObject(DataManager())
}
