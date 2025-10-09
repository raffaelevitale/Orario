//
//  SettingsView.swift
//  Vallauri_da_Vincenzo
//

import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    @Published var backgroundColor: BackgroundColor = .default
    @Published var isCompactNavigation: Bool = false
    @Published var enableNotifications: Bool = true
    @Published var enableLiveActivities: Bool = true
    @Published var enableDailyNotification: Bool = true
    @Published var enableLessonReminders: Bool = true
    @Published var dailyNotificationTime: Date = {
        let calendar = Calendar.current
        return calendar.date(from: DateComponents(hour: 7, minute: 30)) ?? Date()
    }()
    
    // MARK: - Configurazioni Avanzate Notifiche
    @Published var notificationSettings: NotificationSettings = NotificationSettings()
    
    private let userDefaults = UserDefaults.standard
    private let notificationSettingsKey = "AdvancedNotificationSettings"
    
    init() {
        loadSettings()
        
        // Sincronizza le impostazioni base con quelle avanzate
        syncBasicWithAdvancedSettings()
    }
    
    func saveSettings() {
        userDefaults.set(backgroundColor.rawValue, forKey: "backgroundColor")
        userDefaults.set(isCompactNavigation, forKey: "isCompactNavigation")
        userDefaults.set(enableNotifications, forKey: "enableNotifications")
        userDefaults.set(enableLiveActivities, forKey: "enableLiveActivities")
        userDefaults.set(enableDailyNotification, forKey: "enableDailyNotification")
        userDefaults.set(enableLessonReminders, forKey: "enableLessonReminders")
        userDefaults.set(dailyNotificationTime, forKey: "dailyNotificationTime")
        
        // Salva anche le configurazioni avanzate
        saveAdvancedNotificationSettings()
    }
    
    private func loadSettings() {
        if let colorString = userDefaults.object(forKey: "backgroundColor") as? String,
           let color = BackgroundColor(rawValue: colorString) {
            backgroundColor = color
        }
        
        // Valori predefiniti per le nuove installazioni
        let isFirstLaunch = !userDefaults.bool(forKey: "hasLaunchedBefore")
        if isFirstLaunch {
            enableNotifications = true
            enableLiveActivities = true
            enableDailyNotification = true
            enableLessonReminders = true
            userDefaults.set(true, forKey: "hasLaunchedBefore")
            saveSettings()
        } else {
            isCompactNavigation = userDefaults.bool(forKey: "isCompactNavigation")
            enableNotifications = userDefaults.bool(forKey: "enableNotifications")
            enableLiveActivities = userDefaults.bool(forKey: "enableLiveActivities")
            enableDailyNotification = userDefaults.bool(forKey: "enableDailyNotification")
            enableLessonReminders = userDefaults.bool(forKey: "enableLessonReminders")
        }
        
        if let savedTime = userDefaults.object(forKey: "dailyNotificationTime") as? Date {
            dailyNotificationTime = savedTime
        }
        
        // Carica le configurazioni avanzate
        loadAdvancedNotificationSettings()
    }
    
    // MARK: - Gestione Configurazioni Avanzate
    
    private func loadAdvancedNotificationSettings() {
        if let data = userDefaults.data(forKey: notificationSettingsKey),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            notificationSettings = settings
        } else {
            // Prima installazione - inizializza con valori predefiniti
            notificationSettings = NotificationSettings()
            saveAdvancedNotificationSettings()
        }
    }
    
    private func saveAdvancedNotificationSettings() {
        if let data = try? JSONEncoder().encode(notificationSettings) {
            userDefaults.set(data, forKey: notificationSettingsKey)
        }
    }
    
    private func syncBasicWithAdvancedSettings() {
        // Sincronizza le impostazioni base con quelle avanzate per compatibilità
        notificationSettings.enableNotifications = enableNotifications
        notificationSettings.enableLessonReminders = enableLessonReminders
        notificationSettings.enableDailyNotification = enableDailyNotification
        notificationSettings.dailyNotificationTime = dailyNotificationTime
    }
    
    /// Aggiorna configurazione per una specifica materia
    func updateSubjectConfig(_ subject: String, config: SubjectNotificationConfig) {
        if let index = notificationSettings.subjectConfigs.firstIndex(where: { $0.subjectName == subject }) {
            notificationSettings.subjectConfigs[index] = config
        } else {
            notificationSettings.subjectConfigs.append(config)
        }
        saveAdvancedNotificationSettings()
    }
    
    /// Aggiorna programma per un giorno specifico
    func updateDaySchedule(_ day: DaySchedule.DayOfWeek, schedule: DaySchedule) {
        if let index = notificationSettings.daySchedules.firstIndex(where: { $0.dayOfWeek == day }) {
            notificationSettings.daySchedules[index] = schedule
        } else {
            notificationSettings.daySchedules.append(schedule)
        }
        saveAdvancedNotificationSettings()
    }
    
    /// Aggiungi evento di notifica per analytics
    func recordNotificationEvent(_ event: NotificationEvent) {
        notificationSettings.notificationHistory.append(event)
        
        // Mantieni solo gli ultimi 100 eventi per performance
        if notificationSettings.notificationHistory.count > 100 {
            notificationSettings.notificationHistory.removeFirst(notificationSettings.notificationHistory.count - 100)
        }
        
        // Aggiorna metriche
        updatePerformanceMetrics(for: event)
        saveAdvancedNotificationSettings()
    }
    
    private func updatePerformanceMetrics(for event: NotificationEvent) {
        notificationSettings.performanceMetrics.totalNotificationsSent += 1
        
        if event.wasDelivered {
            notificationSettings.performanceMetrics.notificationsDelivered += 1
        }
        
        if event.wasInteracted {
            notificationSettings.performanceMetrics.notificationsInteracted += 1
        }
        
        // Aggiorna engagement per materia
        if let subject = event.subjectName {
            let currentEngagement = notificationSettings.performanceMetrics.subjectEngagement[subject] ?? 0
            notificationSettings.performanceMetrics.subjectEngagement[subject] = currentEngagement + (event.wasInteracted ? 1 : 0)
        }
    }
}

// Extension per rendere SettingsManager disponibile globalmente
extension SettingsManager {
    static let shared = SettingsManager()
}

enum BackgroundColor: String, CaseIterable {
    case `default` = "default"
    case blue = "blue"
    case purple = "purple"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case teal = "teal"
    
    var displayName: String {
        switch self {
        case .default: return "Predefinito"
        case .blue: return "Blu"
        case .purple: return "Viola"
        case .green: return "Verde"
        case .orange: return "Arancione"
        case .red: return "Rosso"
        case .teal: return "Teal"
        }
    }
    
    var colors: [Color] {
        switch self {
        case .default:
            return [.black, .gray.opacity(0.3)]
        case .blue:
            return [.black, .blue.opacity(0.4)]
        case .purple:
            return [.black, .purple.opacity(0.4)]
        case .green:
            return [.black, .green.opacity(0.4)]
        case .orange:
            return [.black, .orange.opacity(0.4)]
        case .red:
            return [.black, .red.opacity(0.4)]
        case .teal:
            return [.black, .teal.opacity(0.4)]
        }
    }
    
    var previewColor: Color {
        switch self {
        case .default: return .gray
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .teal: return .teal
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var dataManager: DataManager
    @State private var showingResetAlert = false
    
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
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Appearance Settings
                        appearanceSection
                        
                        // Navigation Settings
                        navigationSection
                        
                        // Enhanced Notification Settings
                        enhancedNotificationSection
                        
                        // Data Management
                        dataSection
                        
                        // About Section
                        aboutSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .onChange(of: settingsManager.backgroundColor) { _ in
                settingsManager.saveSettings()
            }
            .onChange(of: settingsManager.isCompactNavigation) { _ in
                settingsManager.saveSettings()
            }
            .onChange(of: settingsManager.enableNotifications) { _ in
                settingsManager.saveSettings()
            }
            .onChange(of: settingsManager.enableLiveActivities) { _ in
                settingsManager.saveSettings()
            }
            .onChange(of: settingsManager.enableDailyNotification) { _ in
                settingsManager.saveSettings()
            }
            .onChange(of: settingsManager.enableLessonReminders) { _ in
                settingsManager.saveSettings()
            }
            .onChange(of: settingsManager.dailyNotificationTime) { _ in
                settingsManager.saveSettings()
            }
        }
        .environmentObject(settingsManager)
    }
    
    // MARK: - Helper Methods
    
    private func testNotifications() {
        NotificationManager.shared.sendTestNotification()
    }
    
    private func rescheduleNotifications() {
        // Richiedi permessi se necessario
        NotificationManager.shared.requestPermissions { granted in
            if granted {
                // Usa il sistema avanzato se abilitato, altrimenti il sistema legacy
                if self.settingsManager.notificationSettings.enableSmartScheduling {
                    NotificationManager.shared.scheduleAdvancedNotifications(
                        for: self.dataManager.lessons,
                        settings: self.settingsManager.notificationSettings
                    )
                } else {
                    // Sistema legacy
                    if self.settingsManager.enableLessonReminders {
                        self.dataManager.rescheduleNotifications()
                    }
                    if self.settingsManager.enableDailyNotification {
                        NotificationManager.shared.scheduleDailySchoolNotification(for: self.dataManager.lessons)
                    }
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            Text("⚙️ Impostazioni")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Personalizza la tua esperienza")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.bottom)
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Aspetto", icon: "paintbrush.fill")
            
            VStack(spacing: 16) {
                // Background Color Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Colore di sfondo")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(BackgroundColor.allCases, id: \.self) { color in
                            ColorSelectionView(
                                color: color,
                                isSelected: settingsManager.backgroundColor == color
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    settingsManager.backgroundColor = color
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Navigation Section
    private var navigationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Navigazione", icon: "square.grid.3x1.folder.badge.plus")
            
            VStack(spacing: 0) {
                SettingsRowView(
                    title: "Modalità compatta",
                    subtitle: "Navigation bar ridotta",
                    icon: "rectangle.compress.vertical",
                    isToggle: true,
                    isOn: $settingsManager.isCompactNavigation
                )
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Enhanced Notification Section
    private var enhancedNotificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Notifiche", icon: "bell.fill")
            
            VStack(spacing: 0) {
                // Controlli Base (esistenti)
                SettingsRowView(
                    title: "Notifiche generali",
                    subtitle: "Abilita tutte le notifiche",
                    icon: "bell",
                    isToggle: true,
                    isOn: $settingsManager.enableNotifications
                )
                
                if settingsManager.enableNotifications {
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    SettingsRowView(
                        title: "Live Activities",
                        subtitle: "Mostra lezioni nella Dynamic Island",
                        icon: "circle.dashed",
                        isToggle: true,
                        isOn: $settingsManager.enableLiveActivities
                    )
                    
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    SettingsRowView(
                        title: "Promemoria lezioni",
                        subtitle: "Notifica 5 minuti prima delle lezioni",
                        icon: "clock.badge.exclamationmark",
                        isToggle: true,
                        isOn: $settingsManager.enableLessonReminders
                    )
                    
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    SettingsRowView(
                        title: "Buongiorno quotidiano",
                        subtitle: "Materie del giorno alle 7:30",
                        icon: "sun.max.fill",
                        isToggle: true,
                        isOn: $settingsManager.enableDailyNotification
                    )
                    
                    if settingsManager.enableDailyNotification {
                        Divider()
                            .background(.white.opacity(0.2))
                        
                        // Time picker per l'orario della notifica quotidiana
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.white)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Orario notifica")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                DatePicker(
                                    "",
                                    selection: $settingsManager.dailyNotificationTime,
                                    displayedComponents: [.hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                                .tint(.white)
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
                    
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    // Pulsante per testare le notifiche
                    Button(action: testNotifications) {
                        HStack {
                            Image(systemName: "play.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Testa notifiche")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("Invia una notifica di prova")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                    }
                    
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    // Pulsante per riprogrammare le notifiche
                    Button(action: rescheduleNotifications) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Aggiorna notifiche")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("Riprogramma tutte le notifiche")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                    }
                    
                    // Separatore per le nuove sezioni
                    Divider()
                        .background(.white.opacity(0.4))
                        .padding(.vertical, 8)
                    
                    // Configurazione Avanzata [NUOVO]
                    NavigationLink(destination: AdvancedNotificationConfigView()) {
                        HStack {
                            Image(systemName: "gearshape.2.fill")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Configurazione Avanzata")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("Personalizza per materia e orari")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                    }
                    
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    // Scheduling Personalizzato [NUOVO]
                    NavigationLink(destination: CustomSchedulingView()) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Scheduling Personalizzato")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("Orari e promemoria su misura")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                    }
                    
                    Divider()
                        .background(.white.opacity(0.2))
                    
                    // Analytics & Debug [NUOVO]
                    NavigationLink(destination: NotificationAnalyticsView()) {
                        HStack {
                            Image(systemName: "chart.bar.doc.horizontal.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Analytics & Debug")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("Statistiche e strumenti di debug")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                if settingsManager.notificationSettings.enableAnalytics {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .onChange(of: settingsManager.enableNotifications) { enabled in
            if !enabled {
                // Disabilita tutte le notifiche
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            } else {
                // Riabilita le notifiche usando il sistema avanzato se configurato
                if settingsManager.notificationSettings.enableSmartScheduling {
                    NotificationManager.shared.scheduleAdvancedNotifications(
                        for: dataManager.lessons,
                        settings: settingsManager.notificationSettings
                    )
                } else {
                    rescheduleNotifications()
                }
            }
            // Sincronizza con le impostazioni avanzate
            settingsManager.notificationSettings.enableNotifications = enabled
            settingsManager.saveSettings()
        }
        .onChange(of: settingsManager.enableDailyNotification) { enabled in
            settingsManager.notificationSettings.enableDailyNotification = enabled
            if enabled {
                if settingsManager.notificationSettings.enableSmartScheduling {
                    NotificationManager.shared.scheduleAdvancedNotifications(
                        for: dataManager.lessons,
                        settings: settingsManager.notificationSettings
                    )
                } else {
                    NotificationManager.shared.scheduleDailySchoolNotification(for: dataManager.lessons)
                }
            } else {
                NotificationManager.shared.cancelDailySchoolNotifications()
            }
            settingsManager.saveSettings()
        }
        .onChange(of: settingsManager.enableLessonReminders) { enabled in
            settingsManager.notificationSettings.enableLessonReminders = enabled
            if settingsManager.notificationSettings.enableSmartScheduling {
                NotificationManager.shared.scheduleAdvancedNotifications(
                    for: dataManager.lessons,
                    settings: settingsManager.notificationSettings
                )
            } else {
                rescheduleNotifications()
            }
            settingsManager.saveSettings()
        }
        .onChange(of: settingsManager.dailyNotificationTime) { newTime in
            settingsManager.notificationSettings.dailyNotificationTime = newTime
            if settingsManager.enableDailyNotification {
                NotificationManager.shared.cancelDailySchoolNotifications()
                if settingsManager.notificationSettings.enableSmartScheduling {
                    NotificationManager.shared.scheduleAdvancedNotifications(
                        for: dataManager.lessons,
                        settings: settingsManager.notificationSettings
                    )
                } else {
                    NotificationManager.shared.scheduleDailySchoolNotification(for: dataManager.lessons)
                }
            }
            settingsManager.saveSettings()
        }
    }
    
    // MARK: - Data Section
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Gestione dati", icon: "externaldrive.fill")
            
            VStack(spacing: 0) {
                Button(action: { showingResetAlert = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ripristina dati")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text("Elimina tutti i voti e gli eventi")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding()
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .alert("Ripristina dati", isPresented: $showingResetAlert) {
            Button("Elimina tutto", role: .destructive) {
                // Reset all data
                dataManager.resetAllData()
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text("Questa azione eliminerà definitivamente tutti i voti e gli eventi salvati. Non può essere annullata.")
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Informazioni", icon: "info.circle.fill")
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Orario Vallauri")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Versione 1.0.0")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding()
                
                Divider()
                    .background(.white.opacity(0.2))
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sviluppato da")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Raffaele Vitale")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Supporting Views

struct SectionHeaderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct ColorSelectionView: View {
    let color: BackgroundColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: color.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: isSelected ? 3 : 1)
                    }
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                
                Text(color.displayName)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct SettingsRowView: View {
    let title: String
    let subtitle: String
    let icon: String
    let isToggle: Bool
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            if isToggle {
                Toggle("", isOn: $isOn)
                    .tint(.green)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager())
}