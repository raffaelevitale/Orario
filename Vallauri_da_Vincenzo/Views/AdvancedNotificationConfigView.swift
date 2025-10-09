import SwiftUI

struct AdvancedNotificationConfigView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: ConfigTab = .subjects
    
    enum ConfigTab: String, CaseIterable {
        case subjects = "Materie"
        case timing = "Orari"
        case smart = "Intelligente"
        
        var icon: String {
            switch self {
            case .subjects: return "books.vertical"
            case .timing: return "clock"
            case .smart: return "brain.head.profile"
            }
        }
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
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Tab Selector
                    tabSelector
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case .subjects:
                                subjectsConfigView
                            case .timing:
                                timingConfigView
                            case .smart:
                                smartConfigView
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Indietro") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        settingsManager.saveSettings()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("⚙️ Configurazione Avanzata")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Personalizza notifiche per materia e orari")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ConfigTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        
                        Text(tab.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // MARK: - Subjects Configuration
    private var subjectsConfigView: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Configurazioni per Materia", icon: "books.vertical")
            
            // Controlli globali
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tempo promemoria predefinito")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Minuti prima dell'inizio lezione")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Stepper(
                        "\(settingsManager.notificationSettings.defaultReminderMinutes) min",
                        value: $settingsManager.notificationSettings.defaultReminderMinutes,
                        in: 1...30
                    )
                    .foregroundColor(.white)
                }
                .padding()
                
                Divider()
                    .background(.white.opacity(0.2))
                
                // Toggle per scheduling intelligente
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scheduling Intelligente")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Adatta orari in base ai tuoi pattern")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.notificationSettings.enableSmartScheduling)
                        .tint(.purple)
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Lista materie
            VStack(alignment: .leading, spacing: 12) {
                Text("Configurazioni Specifiche")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                
                LazyVStack(spacing: 8) {
                    ForEach(availableSubjects, id: \.self) { subject in
                        SubjectConfigRowView(
                            subject: subject,
                            config: getConfigForSubject(subject),
                            onConfigChange: { newConfig in
                                updateSubjectConfig(subject, config: newConfig)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Timing Configuration
    private var timingConfigView: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Configurazioni Orari", icon: "clock")
            
            // Ore di silenzio globali
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.indigo)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ore di silenzio globali")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Disabilita notifiche in questi orari")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.notificationSettings.globalQuietHours.isEnabled)
                        .tint(.indigo)
                }
                .padding()
                
                if settingsManager.notificationSettings.globalQuietHours.isEnabled {
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    HStack {
                        Text("Da:")
                            .foregroundColor(.white)
                        
                        DatePicker(
                            "",
                            selection: $settingsManager.notificationSettings.globalQuietHours.startTime,
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .tint(.white)
                        
                        Text("A:")
                            .foregroundColor(.white)
                        
                        DatePicker(
                            "",
                            selection: $settingsManager.notificationSettings.globalQuietHours.endTime,
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .tint(.white)
                    }
                    .padding()
                    
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Consenti notifiche critiche")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text("Permetti notifiche ad alta priorità")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $settingsManager.notificationSettings.globalQuietHours.allowCriticalNotifications)
                            .tint(.orange)
                    }
                    .padding()
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Configurazioni per giorni specifici
            VStack(alignment: .leading, spacing: 12) {
                Text("Programmi Giornalieri")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                
                Text("Personalizza orari per ogni giorno della settimana")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 4)
                
                LazyVStack(spacing: 8) {
                    ForEach(DaySchedule.DayOfWeek.allCases, id: \.self) { day in
                        DayConfigRowView(
                            day: day,
                            schedule: getScheduleForDay(day),
                            onScheduleChange: { newSchedule in
                                updateDaySchedule(day, schedule: newSchedule)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Smart Configuration
    private var smartConfigView: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Funzioni Intelligenti", icon: "brain.head.profile")
            
            VStack(spacing: 0) {
                // Notifiche adattive
                HStack {
                    Image(systemName: "wand.and.rays")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifiche Adattive")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Impara dai tuoi pattern di utilizzo")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.notificationSettings.adaptiveNotifications)
                        .tint(.purple)
                }
                .padding()
                
                Divider()
                    .background(.white.opacity(0.2))
                
                // Notifiche basate su posizione
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifiche Basate su Posizione")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Solo quando sei a scuola o vicino")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.notificationSettings.locationBasedNotifications)
                        .tint(.blue)
                }
                .padding()
                
                Divider()
                    .background(.white.opacity(0.2))
                
                // Gestione festività
                HStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Riconoscimento Festività")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Disabilita automaticamente durante le vacanze")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.notificationSettings.holidayScheduling)
                        .tint(.orange)
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Analytics e Debug
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Raccogli Analytics")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Per migliorare le funzioni intelligenti")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.notificationSettings.enableAnalytics)
                        .tint(.green)
                }
                .padding()
                
                Divider()
                    .background(.white.opacity(0.2))
                
                HStack {
                    Image(systemName: "ladybug")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Modalità Debug")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Mostra informazioni tecniche dettagliate")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.notificationSettings.debugMode)
                        .tint(.red)
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Helper Methods
    
    private var availableSubjects: [String] {
        let lessonsSubjects = dataManager.lessons.map { $0.subject }.filter { $0 != "Intervallo" }
        let configSubjects = settingsManager.notificationSettings.subjectConfigs.map { $0.subjectName }
        return Array(Set(lessonsSubjects + configSubjects)).sorted()
    }
    
    private func getConfigForSubject(_ subject: String) -> SubjectNotificationConfig {
        return settingsManager.notificationSettings.configForSubject(subject) 
            ?? SubjectNotificationConfig(subjectName: subject)
    }
    
    private func updateSubjectConfig(_ subject: String, config: SubjectNotificationConfig) {
        settingsManager.updateSubjectConfig(subject, config: config)
    }
    
    private func getScheduleForDay(_ day: DaySchedule.DayOfWeek) -> DaySchedule {
        return settingsManager.notificationSettings.scheduleForDay(day) 
            ?? DaySchedule(dayOfWeek: day)
    }
    
    private func updateDaySchedule(_ day: DaySchedule.DayOfWeek, schedule: DaySchedule) {
        settingsManager.updateDaySchedule(day, schedule: schedule)
    }
}

// MARK: - Supporting Views

struct SubjectConfigRowView: View {
    let subject: String
    @State private var config: SubjectNotificationConfig
    let onConfigChange: (SubjectNotificationConfig) -> Void
    
    @State private var isExpanded = false
    
    init(subject: String, config: SubjectNotificationConfig, onConfigChange: @escaping (SubjectNotificationConfig) -> Void) {
        self.subject = subject
        self._config = State(initialValue: config)
        self.onConfigChange = onConfigChange
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: config.isEnabled ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(config.isEnabled ? .green : .gray)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(subject)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("\(config.reminderMinutes) min prima • Priorità \(config.priority.rawValue)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }
                .padding()
            }
            
            if isExpanded {
                Divider()
                    .background(.white.opacity(0.2))
                
                VStack(spacing: 12) {
                    // Enable toggle
                    HStack {
                        Text("Abilitato")
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $config.isEnabled)
                            .tint(.green)
                    }
                    
                    // Reminder minutes
                    HStack {
                        Text("Promemoria (minuti prima)")
                            .foregroundColor(.white)
                        Spacer()
                        Stepper("\(config.reminderMinutes)", value: $config.reminderMinutes, in: 1...30)
                            .foregroundColor(.white)
                    }
                    
                    // Priority picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priorità")
                            .foregroundColor(.white)
                        
                        Picker("Priorità", selection: $config.priority) {
                            ForEach(SubjectNotificationConfig.NotificationPriority.allCases, id: \.self) { priority in
                                Text(priority.rawValue).tag(priority)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Weekend reminders
                    HStack {
                        Text("Promemoria weekend")
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $config.enableWeekendReminders)
                            .tint(.blue)
                    }
                }
                .padding()
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: config) { newConfig in
            onConfigChange(newConfig)
        }
    }
}

struct DayConfigRowView: View {
    let day: DaySchedule.DayOfWeek
    @State private var schedule: DaySchedule
    let onScheduleChange: (DaySchedule) -> Void
    
    @State private var isExpanded = false
    
    init(day: DaySchedule.DayOfWeek, schedule: DaySchedule, onScheduleChange: @escaping (DaySchedule) -> Void) {
        self.day = day
        self._schedule = State(initialValue: schedule)
        self.onScheduleChange = onScheduleChange
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: schedule.isEnabled ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(schedule.isEnabled ? .green : .gray)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.rawValue)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text(schedule.isEnabled ? "Attivo" : "Disabilitato")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }
                .padding()
            }
            
            if isExpanded {
                Divider()
                    .background(.white.opacity(0.2))
                
                VStack(spacing: 12) {
                    // Enable toggle
                    HStack {
                        Text("Attivo")
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $schedule.isEnabled)
                            .tint(.green)
                    }
                    
                    if schedule.isEnabled {
                        // Time range
                        HStack {
                            Text("Orario attivo")
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            DatePicker("Da", selection: $schedule.startTime, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.compact)
                                .tint(.white)
                                .labelsHidden()
                            
                            Text("-")
                                .foregroundColor(.white)
                            
                            DatePicker("A", selection: $schedule.endTime, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.compact)
                                .tint(.white)
                                .labelsHidden()
                        }
                        
                        // Quiet hours for this day
                        HStack {
                            Text("Ore di silenzio specifiche")
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { schedule.quietHours != nil },
                                set: { enabled in
                                    if enabled {
                                        schedule.quietHours = QuietHours()
                                    } else {
                                        schedule.quietHours = nil
                                    }
                                }
                            ))
                            .tint(.indigo)
                        }
                        
                        if schedule.quietHours != nil {
                            HStack {
                                DatePicker("Da", selection: Binding(
                                    get: { schedule.quietHours?.startTime ?? Date() },
                                    set: { schedule.quietHours?.startTime = $0 }
                                ), displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.compact)
                                .tint(.white)
                                
                                Text("-")
                                    .foregroundColor(.white)
                                
                                DatePicker("A", selection: Binding(
                                    get: { schedule.quietHours?.endTime ?? Date() },
                                    set: { schedule.quietHours?.endTime = $0 }
                                ), displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.compact)
                                .tint(.white)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: schedule) { newSchedule in
            onScheduleChange(newSchedule)
        }
    }
}

#Preview {
    AdvancedNotificationConfigView()
        .environmentObject(SettingsManager())
        .environmentObject(DataManager())
}