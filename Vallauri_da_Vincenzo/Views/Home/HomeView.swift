//
//  HomeView.swift
//  Vallauri_da_Vincenzo
//

import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var plannerManager = WeeklyPlannerManager()
    @State private var currentTime = Date()
    @State private var isGreetingVisible = true
    @Binding var selectedTab: Int
    
    private let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12:
            return "Buongiorno"
        case 12..<17:
            return "Buon pomeriggio"
        case 17..<22:
            return "Buonasera"
        default:
            return "Buonanotte"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: currentTime).capitalized
    }
    
    private var isSchoolTime: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentTime)
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentMinutes = hour * 60 + minute
        
        // Lunedì-Venerdì (2-6), dalle 7:50 alle 14:00
        return weekday >= 2 && weekday <= 6 && currentMinutes >= 470 && currentMinutes <= 840
    }
    
    private var currentLesson: Lesson? {
        guard isSchoolTime else { return nil }
        return dataManager.getCurrentLesson()
    }
    
    var nextLesson: Lesson? {
        guard isSchoolTime else { return nil }
        return dataManager.getNextLesson()
    }
    
    private var todayTasks: [PlannerTask] {
        plannerManager.getTasksForDay(currentTime)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: settingsManager.backgroundColor.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header con saluto e data
                        headerView
                        
                        // Sezione lezione attuale/prossima
                        if isSchoolTime {
                            currentLessonView
                        } else {
                            nextSchoolDayView
                        }
                        
                        // Sezione compiti/eventi di oggi
                        if !todayTasks.isEmpty {
                            todayTasksView
                        }
                        
                        // Stats veloci
                        quickStatsView
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchView()) {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
            }
            .onReceive(timer) { _ in
                currentTime = Date()
                // Forza aggiornamento del DataManager per aggiornare la UI
                dataManager.objectWillChange.send()
            }
            .onAppear {
                // Animazione del saluto
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeInOut(duration: 1)) {
                        isGreetingVisible = false
                    }
                }
            }
        }
    }
    
    // MARK: - Header View
    var headerView: some View {
        VStack(spacing: 16) {
            if isGreetingVisible {
                Text(greeting)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .transition(.opacity.combined(with: .scale))
            } else {
                Text(formattedDate)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(height: 80)
        .animation(.easeInOut(duration: 1), value: isGreetingVisible)
    }
    
    // MARK: - Current Lesson View
    var currentLessonView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let lesson = currentLesson {
                currentLessonCard(lesson)
            } else if let nextLesson = nextLesson {
                nextLessonCard(nextLesson)
            } else {
                noLessonsCard
            }
        }
    }
    
    func currentLessonCard(_ lesson: Lesson) -> some View {
        Button(action: {
            selectedTab = 1 // Navigate to schedule tab
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("Lezione in corso")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green.opacity(0.7))
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(lesson.subject)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.7))
                        Text(lesson.teacher)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white.opacity(0.7))
                        Text(lesson.classroom)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(lesson.startTime) - \(lesson.endTime)")
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding()
            .glassmorphism(tintColor: settingsManager.backgroundColor.colors.first ?? .blue)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.green.opacity(0.5), lineWidth: 2)
            }
            .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(BounceButtonStyle())
    }
    
    func nextLessonCard(_ lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Prossima lezione")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(lesson.subject)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white.opacity(0.7))
                    Text(lesson.teacher)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.white.opacity(0.7))
                    Text(lesson.classroom)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Inizia alle \(lesson.startTime)")
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding()
        .glassmorphism(tintColor: settingsManager.backgroundColor.colors.first ?? .blue)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.orange.opacity(0.5), lineWidth: 2)
        }
        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    var noLessonsCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz.fill")
                .font(.title)
                .foregroundColor(.blue)
            
            Text("Nessuna lezione in corso")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Pausa o fine giornata scolastica")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .glassmorphism(tintColor: settingsManager.backgroundColor.colors.first ?? .blue)
        .shadow(color: .blue.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Next School Day View
    var nextSchoolDayView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Prossimo giorno di scuola")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let nextSchoolDay = getNextSchoolDay() {
                Text(nextSchoolDay)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding()
        .glassmorphism(tintColor: settingsManager.backgroundColor.colors.first ?? .blue)
        .shadow(color: .blue.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Today Tasks View
    var todayTasksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Eventi di oggi")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                BadgeView(count: todayTasks.count, color: .orange)
            }
            
            VStack(spacing: 12) {
                ForEach(todayTasks.prefix(3)) { task in
                    TaskRowView(task: task)
                }
                
                if todayTasks.count > 3 {
                    HStack {
                        Spacer()
                        Text("e altri \(todayTasks.count - 3)...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .glassmorphism(tintColor: settingsManager.backgroundColor.colors.first ?? .blue)
        .shadow(color: .orange.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Quick Stats View
    var quickStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Riepilogo rapido")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                StatCardView(
                    title: "Eventi totali",
                    value: "\(plannerManager.totalTasks)",
                    color: .blue,
                    icon: "calendar.badge.plus",
                    backgroundColor: settingsManager.backgroundColor.colors.first ?? .blue
                )
                
                StatCardView(
                    title: "Completati",
                    value: "\(plannerManager.completedTasks)",
                    color: .green,
                    icon: "checkmark.circle.fill",
                    backgroundColor: settingsManager.backgroundColor.colors.first ?? .blue
                )
                
                StatCardView(
                    title: "In scadenza",
                    value: "\(plannerManager.overdueTasks)",
                    color: .red,
                    icon: "exclamationmark.triangle.fill",
                    backgroundColor: settingsManager.backgroundColor.colors.first ?? .blue
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    func getNextSchoolDay() -> String? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentTime)
        
        if weekday == 1 { // Domenica
            return "Lunedì"
        } else if weekday == 7 { // Sabato
            return "Lunedì"
        } else if weekday >= 2 && weekday <= 6 { // Lunedì-Venerdì
            let hour = calendar.component(.hour, from: currentTime)
            if hour >= 14 { // Dopo le 14:00
                if weekday == 6 { // Venerdì sera
                    return "Lunedì"
                } else {
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentTime)!
                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEEE"
                    formatter.locale = Locale(identifier: "it_IT")
                    return formatter.string(from: tomorrow).capitalized
                }
            } else {
                return "Oggi"
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Views
struct TaskRowView: View {
    let task: PlannerTask
    
    private var dueDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: task.dueDate)
    }
    
    private var isOverdue: Bool {
        task.dueDate < Date() && !task.isCompleted
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(task.type.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(dueDateText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(isOverdue ? .red : .white.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isOverdue ? .red.opacity(0.2) : .white.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                HStack {
                    Text(task.subject)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(task.type.rawValue)
                        .font(.caption)
                        .foregroundColor(task.type.color)
                }
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            
            Image(systemName: task.type.icon)
                .font(.caption)
                .foregroundColor(task.type.color)
        }
        .padding(.vertical, 8)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
            .environmentObject(DataManager())
            .environmentObject(SettingsManager())
    }
}
