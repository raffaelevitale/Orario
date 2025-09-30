//
//  StudyStatsView.swift
//  Vallauri_da_Vincenzo
//

import SwiftUI
import Combine

struct StudyStatsView: View {
    @ObservedObject var timerManager: StudyTimerManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var showingAllSessions = false
    
    enum StatsPeriod: String, CaseIterable {
        case week = "Settimana"
        case month = "Mese"
        case all = "Tutto"
        
        var icon: String {
            switch self {
            case .week: return "calendar.day.timeline.left"
            case .month: return "calendar"
            case .all: return "clock.arrow.circlepath"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [.black, .gray.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Period Selector
                        periodSelector
                        
                        // Overview Stats
                        overviewStats
                        
                        // Weekly Chart
                        if selectedPeriod == .week {
                            weeklyChart
                        }
                        
                        // Subject Breakdown
                        subjectBreakdown
                        
                        // Achievement Cards
                        achievementCards
                        
                        // Recent Sessions
                        recentSessionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Statistiche Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingAllSessions) {
                AllSessionsView(timerManager: timerManager)
            }
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Button(action: { 
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: period.icon)
                            .font(.caption)
                        Text(period.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedPeriod == period ? .black : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        selectedPeriod == period ? 
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
    }
    
    // MARK: - Overview Stats
    
    private var overviewStats: some View {
        VStack(spacing: 16) {
            Text("Panoramica generale")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCardLarge(
                    title: "Tempo totale",
                    value: timerManager.formatDuration(timerManager.totalStudyTime),
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatCardLarge(
                    title: "Sessioni",
                    value: "\\(timerManager.totalSessions)",
                    icon: "play.circle.fill",
                    color: .green
                )
                
                StatCardLarge(
                    title: "Tasso completamento",
                    value: String(format: "%.0f%%", timerManager.completionRate * 100),
                    icon: "target",
                    color: .orange
                )
                
                StatCardLarge(
                    title: "Striscia giorni",
                    value: "\\(timerManager.getStreakDays())",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
    }
    
    // MARK: - Weekly Chart
    
    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Studio questa settimana")
                .font(.headline)
                .foregroundColor(.white)
            
            let weeklyStats = timerManager.getWeeklyStats()
            
            VStack(spacing: 12) {
                ForEach(weeklyStats) { stat in
                    HStack {
                        Text(dayName(for: stat.date))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 30, alignment: .leading)
                        
                        ProgressView(value: Double(stat.totalStudyTime), total: Double(maxStudyTime(in: weeklyStats)))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(y: 3)
                        
                        Text(formatMinutes(stat.totalStudyTime))
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func maxStudyTime(in stats: [DailyStats]) -> Int {
        stats.map { $0.totalStudyTime }.max() ?? 1
    }
    
    private func formatMinutes(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes)m"
    }
    
    // MARK: - Subject Breakdown
    
    private var subjectBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tempo per materia")
                .font(.headline)
                .foregroundColor(.white)
            
            let topSubjects = timerManager.getTopSubjects(limit: 5)
            
            if topSubjects.isEmpty {
                Text("Nessuna sessione di studio registrata")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(topSubjects.enumerated()), id: \.offset) { index, subjectTuple in
                        SubjectProgressRow(
                            subject: subjectTuple.subject,
                            time: timerManager.formatDuration(subjectTuple.time),
                            progress: Double(subjectTuple.time) / Double(topSubjects[0].time),
                            color: getSubjectColor(for: index)
                        )
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Achievement Cards
    
    private var achievementCards: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Obiettivi")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                AchievementCard(
                    title: "Studioso",
                    description: "\\(timerManager.totalSessions) sessioni completate",
                    icon: "graduationcap.fill",
                    color: .purple,
                    isUnlocked: timerManager.totalSessions >= 10
                )
                
                AchievementCard(
                    title: "Costante",
                    description: "\\(timerManager.getStreakDays()) giorni di fila",
                    icon: "flame.fill",
                    color: .orange,
                    isUnlocked: timerManager.getStreakDays() >= 7
                )
            }
        }
    }
    
    // MARK: - Recent Sessions
    
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Sessioni recenti")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Vedi tutte") {
                    showingAllSessions = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                ForEach(timerManager.sessions.prefix(5)) { session in
                    SessionRowView(session: session)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Methods
    
    private func getSubjectColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .red, .purple]
        return colors[index % colors.count]
    }
}

// MARK: - Supporting Views

struct StatCardLarge: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        }
    }
}

struct SubjectProgressRow: View {
    let subject: String
    let time: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(subject)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(time)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 1.5)
        }
    }
}

struct AchievementCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? color : .gray)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isUnlocked ? color.opacity(0.2) : .gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? color.opacity(0.5) : .gray.opacity(0.3), lineWidth: 1)
        }
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

struct SessionRowView: View {
    let session: StudySession
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundColor(session.isCompleted ? .green : .red)
            
            // Session info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.subject)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\\(session.type.rawValue) • \\(session.formattedDuration)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Date
            Text(session.dateFormatted)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AllSessionsView: View {
    @ObservedObject var timerManager: StudyTimerManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [.black, .gray.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(timerManager.sessions) { session in
                            SessionRowView(session: session)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Tutte le Sessioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    StudyStatsView(timerManager: StudyTimerManager())
}
