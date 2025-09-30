//
//  StudyTimerView.swift
//  Vallauri_da_Vincenzo
//

import SwiftUI
import Combine

struct StudyTimerView: View {
    @StateObject private var timerManager = StudyTimerManager()
    @EnvironmentObject var dataManager: DataManager
    @State private var showingSubjectSelection = false
    @State private var showingSettings = false
    @State private var showingStats = false
    @State private var selectedTimerType: TimerType = .pomodoro
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.black, .gray.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with stats
                    headerView
                    
                    // Timer display
                    timerDisplayView
                    
                    // Controls
                    controlsView
                    
                    // Recent sessions
                    if !timerManager.sessions.isEmpty {
                        recentSessionsView
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Study Timer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingStats = true }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showingSubjectSelection) {
                SubjectSelectionView(
                    subjects: dataManager.getAvailableSubjects(),
                    selectedType: selectedTimerType,
                    timerManager: timerManager
                )
            }
            .sheet(isPresented: $showingSettings) {
                TimerSettingsView(timerManager: timerManager)
            }
            .sheet(isPresented: $showingStats) {
                StudyStatsView(timerManager: timerManager)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Quick stats
            HStack(spacing: 20) {
                QuickStatView(
                    icon: "flame.fill",
                    value: "\(timerManager.getStreakDays())",
                    label: "Giorni",
                    color: .orange
                )
                
                QuickStatView(
                    icon: "clock.fill",
                    value: timerManager.formatDuration(timerManager.getTotalStudyTimeThisWeek()),
                    label: "Questa settimana",
                    color: .blue
                )
                
                QuickStatView(
                    icon: "target",
                    value: "\(timerManager.pomodoroCount)",
                    label: "Pomodori oggi",
                    color: .green
                )
            }
            
            // Timer type selector
            HStack(spacing: 0) {
                ForEach(TimerType.allCases, id: \.self) { type in
                    Button(action: { 
                        selectedTimerType = type
                        if timerManager.currentState == .idle {
                            updateTimerForType(type)
                        }
                    }) {
                        Text(type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTimerType == type ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedTimerType == type ? 
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
            
            // Current subject (if timer is running)
            if !timerManager.selectedSubject.isEmpty {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.subheadline)
                    Text(timerManager.selectedSubject)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
        .padding()
    }
    
    // MARK: - Timer Display
    
    private var timerDisplayView: some View {
        VStack(spacing: 24) {
            // Timer circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 280, height: 280)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: timerManager.getProgressPercentage())
                    .stroke(
                        timerManager.currentState.color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timerManager.getProgressPercentage())
                
                // Time display
                VStack(spacing: 8) {
                    Text(timerManager.formatTime(timerManager.remainingTime))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(timerManager.currentState.rawValue)
                        .font(.headline)
                        .foregroundColor(timerManager.currentState.color)
                        .fontWeight(.semibold)
                }
            }
            
            // Session info
            if timerManager.currentState != .idle {
                VStack(spacing: 8) {
                    if timerManager.currentState == .running || timerManager.currentState == .paused {
                        Text("Sessione \(selectedTimerType.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if timerManager.selectedType == .pomodoro && timerManager.pomodoroCount > 0 {
                        Text("Pomodoro \(timerManager.pomodoroCount + 1)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - Controls
    
    private var controlsView: some View {
        VStack(spacing: 20) {
            // Main control buttons
            HStack(spacing: 24) {
                if timerManager.currentState == .idle {
                    // Start button
                    Button(action: { showingSubjectSelection = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.title2)
                            Text("Inizia")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(.green)
                        .clipShape(Capsule())
                    }
                } else {
                    // Pause/Resume button
                    Button(action: {
                        if timerManager.currentState == .running || timerManager.currentState == .shortBreak || timerManager.currentState == .longBreak {
                            timerManager.pauseTimer()
                        } else if timerManager.currentState == .paused {
                            timerManager.resumeTimer()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: timerManager.currentState == .paused ? "play.fill" : "pause.fill")
                                .font(.title2)
                            Text(timerManager.currentState == .paused ? "Riprendi" : "Pausa")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(timerManager.currentState == .paused ? .green : .orange)
                        .clipShape(Capsule())
                    }
                    
                    // Stop button
                    Button(action: {
                        timerManager.stopTimer(completed: false)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                            Text("Stop")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(.red)
                        .clipShape(Capsule())
                    }
                }
            }
            
            // Quick duration buttons (only when idle)
            if timerManager.currentState == .idle {
                VStack(spacing: 12) {
                    Text("Durata rapida")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 12) {
                        QuickDurationButton(duration: 15, timerManager: timerManager, selectedType: $selectedTimerType)
                        QuickDurationButton(duration: 25, timerManager: timerManager, selectedType: $selectedTimerType)
                        QuickDurationButton(duration: 45, timerManager: timerManager, selectedType: $selectedTimerType)
                        QuickDurationButton(duration: 60, timerManager: timerManager, selectedType: $selectedTimerType)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Recent Sessions
    
    private var recentSessionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sessioni recenti")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Vedi tutte") {
                    showingStats = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(timerManager.sessions.prefix(5)) { session in
                        RecentSessionCard(session: session)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Helper Methods
    
    private func updateTimerForType(_ type: TimerType) {
        timerManager.selectedType = type
        switch type {
        case .pomodoro:
            timerManager.remainingTime = timerManager.pomodoroSession
        case .custom:
            timerManager.remainingTime = timerManager.customDuration
        }
    }
}

// MARK: - Supporting Views

struct QuickStatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct QuickDurationButton: View {
    let duration: Int
    @ObservedObject var timerManager: StudyTimerManager
    @Binding var selectedType: TimerType
    
    var body: some View {
        Button(action: {
            selectedType = .custom
            timerManager.customDuration = duration * 60
            timerManager.remainingTime = duration * 60
        }) {
            Text("\(duration)m")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }
}

struct RecentSessionCard: View {
    let session: StudySession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(session.isCompleted ? .green : .red)
                
                Spacer()
                
                Text(session.formattedDuration)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Text(session.subject)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(session.dateFormatted)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 140)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(session.isCompleted ? .green.opacity(0.3) : .red.opacity(0.3), lineWidth: 1)
        }
    }
}

struct SubjectSelectionView: View {
    let subjects: [String]
    let selectedType: TimerType
    @ObservedObject var timerManager: StudyTimerManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSubject = ""
    
    // Extracted subviews to help the compiler type-check faster
    private var gradientBackground: some View {
        LinearGradient(
            colors: [Color.black, Color.gray.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var timerInfoView: some View {
        VStack(spacing: 16) {
            Text("Sessione \(selectedType.rawValue)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            let duration = selectedType == .pomodoro ? timerManager.pomodoroSession : timerManager.customDuration
            Text("Durata: \(timerManager.formatDuration(duration))")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var subjectSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Seleziona materia")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                ForEach(subjects, id: \.self) { subject in
                    subjectButton(subject: subject)
                }
            }
        }
    }

    private var startSessionButton: some View {
        Button(action: {
            timerManager.startTimer(subject: selectedSubject, type: selectedType)
            dismiss()
        }) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.headline)
                Text("Inizia sessione")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.green)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedSubject.isEmpty)
    }
    
    private func subjectButton(subject: String) -> some View {
        Button(action: { selectedSubject = subject }) {
            Text(subject)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(selectedSubject == subject ? .black : .white)
                .padding()
                .frame(maxWidth: .infinity)
                .background {
                    if selectedSubject == subject {
                        Color.white
                    } else {
                        Rectangle().fill(.ultraThinMaterial)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            selectedSubject == subject ? .clear : .white.opacity(0.3),
                            lineWidth: 1
                        )
                }
        }
    }

    private var contentView: some View {
        VStack(spacing: 24) {
            // Timer info
            timerInfoView

            // Subject selection
            subjectSelectionSection

            Spacer()

            // Start button
            startSessionButton
        }
        .padding()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                gradientBackground
                contentView
            }
            .navigationTitle("Inizia Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annulla") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                if !subjects.isEmpty {
                    selectedSubject = subjects[0]
                }
            }
        }
    }
}

#Preview {
    StudyTimerView()
        .environmentObject(DataManager())
}
