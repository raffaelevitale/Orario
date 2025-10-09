import SwiftUI

struct CustomSchedulingView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: SchedulingTab = .daily
    @State private var showingAddReminder = false
    @State private var editingReminder: CustomReminder?
    
    enum SchedulingTab: String, CaseIterable {
        case daily = "Giornaliero"
        case reminders = "Promemoria"
        case patterns = "Pattern"
        
        var icon: String {
            switch self {
            case .daily: return "calendar.day.timeline.left"
            case .reminders: return "bell.badge.fill"
            case .patterns: return "repeat"
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
                            case .daily:
                                dailySchedulingView
                            case .reminders:
                                customRemindersView
                            case .patterns:
                                patternsView
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
                    if selectedTab == .reminders {
                        Button("Aggiungi") {
                            showingAddReminder = true
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            AddCustomReminderView { reminder in
                settingsManager.notificationSettings.customReminders.append(reminder)
                settingsManager.saveSettings()
            }
        }
        .sheet(item: $editingReminder) { reminder in
            EditCustomReminderView(reminder: reminder) { updatedReminder in
                if let index = settingsManager.notificationSettings.customReminders.firstIndex(where: { $0.id == reminder.id }) {
                    settingsManager.notificationSettings.customReminders[index] = updatedReminder
                    settingsManager.saveSettings()
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("📅 Scheduling Personalizzato")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Configura orari e promemoria personalizzati")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(SchedulingTab.allCases, id: \.self) { tab in
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
    
    // MARK: - Daily Scheduling
    private var dailySchedulingView: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Programmazione Giornaliera", icon: "calendar.day.timeline.left")
            
            // Panoramica settimanale
            weeklyOverviewCard
            
            // Configurazioni per giorno
            VStack(alignment: .leading, spacing: 12) {
                Text("Configurazioni Dettagliate")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                
                LazyVStack(spacing: 8) {
                    ForEach(DaySchedule.DayOfWeek.allCases, id: \.self) { day in
                        DayScheduleDetailCard(
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
    
    // MARK: - Custom Reminders
    private var customRemindersView: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Promemoria Personalizzati", icon: "bell.badge.fill")
            
            if settingsManager.notificationSettings.customReminders.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Nessun promemoria personalizzato")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Tocca 'Aggiungi' per creare il tuo primo promemoria personalizzato")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Button("Crea Promemoria") {
                        showingAddReminder = true
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                // Lista promemoria
                LazyVStack(spacing: 8) {
                    ForEach(settingsManager.notificationSettings.customReminders) { reminder in
                        CustomReminderCard(
                            reminder: reminder,
                            onEdit: {
                                editingReminder = reminder
                            },
                            onDelete: {
                                deleteReminder(reminder)
                            },
                            onToggle: { isEnabled in
                                toggleReminder(reminder, enabled: isEnabled)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Patterns
    private var patternsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Pattern e Automazioni", icon: "repeat")
            
            // Pattern di utilizzo
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Analisi Pattern di Utilizzo")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Mostra statistiche sui tuoi orari")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: PatternAnalysisView()) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Automazioni
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gestione Festività")
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
                
                if settingsManager.notificationSettings.holidayScheduling {
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Festività Riconosciute")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("• Vacanze estive (Giugno - Agosto)")
                        Text("• Vacanze natalizie (23 Dic - 6 Gen)")
                        Text("• Vacanze pasquali")
                        Text("• Festività nazionali")
                        
                        ForEach([
                            "• Vacanze estive (Giugno - Agosto)",
                            "• Vacanze natalizie (23 Dic - 6 Gen)",
                            "• Vacanze pasquali",
                            "• Festività nazionali"
                        ], id: \.self) { holiday in
                            Text(holiday)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding()
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Smart suggestions
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Suggerimenti Intelligenti")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Propone automaticamente miglioramenti")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settingsManager.notificationSettings.adaptiveNotifications)
                        .tint(.yellow)
                }
                .padding()
                
                if settingsManager.notificationSettings.adaptiveNotifications {
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Funzionalità Attive:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                                .frame(width: 16)
                            Text("Ottimizzazione orari in base all'utilizzo")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        HStack {
                            Image(systemName: "chart.xyaxis.line")
                                .foregroundColor(.blue)
                                .frame(width: 16)
                            Text("Suggerimenti per ridurre interruzioni")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.green)
                                .frame(width: 16)
                            Text("Personalizzazione automatica priorità")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding()
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Supporting Views
    
    private var weeklyOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Panoramica Settimanale")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(DaySchedule.DayOfWeek.allCases, id: \.self) { day in
                    let schedule = getScheduleForDay(day)
                    let isEnabled = schedule.isEnabled
                    
                    VStack(spacing: 4) {
                        Text(String(day.rawValue.prefix(3)))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Circle()
                            .fill(isEnabled ? Color.green : Color.gray.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: isEnabled ? "checkmark" : "xmark")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            
            HStack {
                Text("Giorni attivi: \(activeDaysCount)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("Quiet hours: \(quietHoursCount)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Methods
    
    private var activeDaysCount: Int {
        settingsManager.notificationSettings.daySchedules.filter { $0.isEnabled }.count
    }
    
    private var quietHoursCount: Int {
        let globalQuiet = settingsManager.notificationSettings.globalQuietHours.isEnabled ? 1 : 0
        let daySpecific = settingsManager.notificationSettings.daySchedules.compactMap { $0.quietHours }.count
        return globalQuiet + daySpecific
    }
    
    private func getScheduleForDay(_ day: DaySchedule.DayOfWeek) -> DaySchedule {
        return settingsManager.notificationSettings.scheduleForDay(day) 
            ?? DaySchedule(dayOfWeek: day)
    }
    
    private func updateDaySchedule(_ day: DaySchedule.DayOfWeek, schedule: DaySchedule) {
        settingsManager.updateDaySchedule(day, schedule: schedule)
    }
    
    private func deleteReminder(_ reminder: CustomReminder) {
        settingsManager.notificationSettings.customReminders.removeAll { $0.id == reminder.id }
        settingsManager.saveSettings()
    }
    
    private func toggleReminder(_ reminder: CustomReminder, enabled: Bool) {
        if let index = settingsManager.notificationSettings.customReminders.firstIndex(where: { $0.id == reminder.id }) {
            settingsManager.notificationSettings.customReminders[index].isEnabled = enabled
            settingsManager.saveSettings()
        }
    }
}

// MARK: - Day Schedule Detail Card

struct DayScheduleDetailCard: View {
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
            // Header
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Circle()
                        .fill(schedule.isEnabled ? Color.green : Color.gray.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(day.rawValue.prefix(1)))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.rawValue)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text(statusText)
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
                
                VStack(spacing: 16) {
                    // Enable toggle
                    HStack {
                        Text("Attivo")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $schedule.isEnabled)
                            .tint(.green)
                    }
                    
                    if schedule.isEnabled {
                        // Active hours
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Orario Attivo")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            HStack {
                                DatePicker("Inizio", selection: $schedule.startTime, displayedComponents: [.hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .tint(.white)
                                
                                Text("-")
                                    .foregroundColor(.white)
                                
                                DatePicker("Fine", selection: $schedule.endTime, displayedComponents: [.hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .tint(.white)
                            }
                        }
                        
                        // Quiet hours
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Ore di Silenzio")
                                    .font(.subheadline)
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
    
    private var statusText: String {
        if !schedule.isEnabled {
            return "Disabilitato"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let start = formatter.string(from: schedule.startTime)
        let end = formatter.string(from: schedule.endTime)
        
        var text = "\(start) - \(end)"
        
        if schedule.quietHours != nil {
            text += " • Quiet hours attive"
        }
        
        return text
    }
}

// MARK: - Custom Reminder Card

struct CustomReminderCard: View {
    let reminder: CustomReminder
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: (Bool) -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text(timeString)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(reminder.repeatPattern.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { reminder.isEnabled },
                    set: { onToggle($0) }
                ))
                .tint(.green)
            }
            .padding()
            
            // Action buttons
            HStack(spacing: 0) {
                Button("Modifica") {
                    onEdit()
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                
                Divider()
                    .background(.white.opacity(0.2))
                    .frame(height: 24)
                
                Button("Elimina") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .background(.ultraThinMaterial.opacity(0.5))
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Elimina Promemoria", isPresented: $showingDeleteAlert) {
            Button("Elimina", role: .destructive) {
                onDelete()
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text("Sei sicuro di voler eliminare questo promemoria?")
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: reminder.time)
    }
}

// MARK: - Supporting Views (Placeholders)

struct AddCustomReminderView: View {
    let onSave: (CustomReminder) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var time = Date()
    @State private var repeatPattern = CustomReminder.RepeatPattern.never
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Custom Reminder View - Coming Soon")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle("Nuovo Promemoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
    }
}

struct EditCustomReminderView: View {
    let reminder: CustomReminder
    let onSave: (CustomReminder) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Edit Custom Reminder View - Coming Soon")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle("Modifica Promemoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
    }
}

struct PatternAnalysisView: View {
    var body: some View {
        VStack {
            Text("Pattern Analysis View - Coming Soon")
                .font(.title)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationTitle("Analisi Pattern")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CustomSchedulingView()
        .environmentObject(SettingsManager())
}