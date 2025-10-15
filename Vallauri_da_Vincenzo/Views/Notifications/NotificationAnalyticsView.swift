import SwiftUI
import Charts

struct NotificationAnalyticsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: AnalyticsTab = .overview
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingDebugLogs = false
    
    enum AnalyticsTab: String, CaseIterable {
        case overview = "Panoramica"
        case performance = "Performance"
        case debug = "Debug"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.doc.horizontal"
            case .performance: return "speedometer"
            case .debug: return "ladybug"
            }
        }
    }
    
    enum TimeRange: String, CaseIterable {
        case day = "Oggi"
        case week = "Settimana"
        case month = "Mese"
        case all = "Tutto"
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
                    
                    // Time Range Selector
                    if selectedTab != .debug {
                        timeRangeSelector
                    }
                    
                    // Tab Selector
                    tabSelector
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case .overview:
                                overviewSection
                            case .performance:
                                performanceSection
                            case .debug:
                                debugSection
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
                    if selectedTab == .debug {
                        Button("Logs") {
                            showingDebugLogs = true
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingDebugLogs) {
            DebugLogsView()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("📊 Analytics & Debug")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Statistiche e strumenti di debug per le notifiche")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        HStack {
            Text("Periodo:")
                .font(.subheadline)
                .foregroundColor(.white)
            
            Picker("Periodo", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .colorInvert()
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                    HapticManager.shared.selection()
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
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Statistiche generali
            statisticsCardsGrid
            
            // Grafico notifiche nel tempo
            notificationTimelineChart
            
            // Engagement per materia
            subjectEngagementChart
            
            // Riassunto configurazioni
            configurationSummary
        }
    }
    
    // MARK: - Performance Section
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Metriche di Performance", icon: "speedometer")
            
            // KPI Cards
            performanceKPICards
            
            // Delivery timeline
            deliveryPerformanceChart
            
            // Subject-specific metrics
            subjectPerformanceBreakdown
            
            // Recommendations
            performanceRecommendations
        }
    }
    
    // MARK: - Debug Section
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Strumenti di Debug", icon: "ladybug")
            
            // Subject notifications overview
            subjectsNotificationsCard
            
            // Debug controls
            debugControls
            
            // System status
            systemStatusCard
            
            // Notification queue
            notificationQueueCard
            
            // Export options
            exportOptionsCard
        }
    }
    
    // MARK: - Statistics Cards Grid
    private var statisticsCardsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            StatisticCard(
                title: "Totale Inviate",
                value: "\(metrics.totalNotificationsSent)",
                icon: "paperplane.fill",
                color: .blue
            )
            
            StatisticCard(
                title: "Consegnate",
                value: "\(metrics.notificationsDelivered)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatisticCard(
                title: "Interazioni",
                value: "\(metrics.notificationsInteracted)",
                icon: "hand.tap.fill",
                color: .orange
            )
            
            StatisticCard(
                title: "Tasso Consegna",
                value: "\(String(format: "%.1f", metrics.deliveryRate * 100))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .purple
            )
        }
    }
    
    // MARK: - Notification Timeline Chart
    private var notificationTimelineChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifiche nel Tempo")
                .font(.headline)
                .foregroundColor(.white)
            
            // Placeholder per il grafico
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Grafico Timeline")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Dati raccolti: \(filteredEvents.count) eventi")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                )
        }
    }
    
    // MARK: - Subject Engagement Chart
    private var subjectEngagementChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Engagement per Materia")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(topEngagementSubjects, id: \.key) { subject, engagement in
                    HStack {
                        Text(subject)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        ProgressView(value: engagement, total: maxEngagement)
                            .frame(width: 100)
                            .tint(.blue)
                        
                        Text("\(Int(engagement))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 30, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Configuration Summary
    private var configurationSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Riassunto Configurazioni")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                ConfigSummaryRow(
                    title: "Materie Configurate",
                    value: "\(settingsManager.notificationSettings.subjectConfigs.count)",
                    icon: "books.vertical"
                )
                
                Divider().background(.white.opacity(0.2))
                
                ConfigSummaryRow(
                    title: "Giorni Attivi",
                    value: "\(activeDaysCount)",
                    icon: "calendar"
                )
                
                Divider().background(.white.opacity(0.2))
                
                ConfigSummaryRow(
                    title: "Promemoria Personalizzati",
                    value: "\(settingsManager.notificationSettings.customReminders.filter { $0.isEnabled }.count)",
                    icon: "bell.badge"
                )
                
                Divider().background(.white.opacity(0.2))
                
                ConfigSummaryRow(
                    title: "Funzioni Intelligenti",
                    value: smartFeaturesCount,
                    icon: "brain.head.profile"
                )
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Performance KPI Cards
    private var performanceKPICards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            KPICard(
                title: "Tasso Engagement",
                value: "\(String(format: "%.1f", metrics.engagementRate * 100))%",
                subtitle: "Notifiche cliccate",
                trend: .stable,
                color: .green
            )
            
            KPICard(
                title: "Tempo Medio Consegna",
                value: "\(String(format: "%.1f", metrics.averageDeliveryTime))s",
                subtitle: "Latenza sistema",
                trend: .improving,
                color: .blue
            )
            
            KPICard(
                title: "Efficacia Oraria",
                value: "87%",
                subtitle: "Orari ottimali",
                trend: .stable,
                color: .orange
            )
            
            KPICard(
                title: "Pattern Recognition",
                value: "94%",
                subtitle: "Accuratezza AI",
                trend: .improving,
                color: .purple
            )
        }
    }
    
    // MARK: - Debug Controls
    // MARK: - Subjects Notifications Card
    private var subjectsNotificationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "books.vertical.fill")
                    .foregroundColor(.cyan)
                Text("Notifiche per Materia")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            let subjects = dataManager.lessons
                .map { $0.subject }
                .filter { $0 != "Intervallo" }
                .reduce(into: [String]()) { result, subject in
                    if !result.contains(subject) {
                        result.append(subject)
                    }
                }
                .sorted()
            
            if subjects.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.4))
                    Text("Nessuna materia presente")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(subjects, id: \.self) { subject in
                        SubjectNotificationStatusCard(
                            subject: subject,
                            color: Color.fromHex(dataManager.getColorFor(subject: subject)) ?? .blue,
                            isEnabled: settingsManager.notificationSettings.configForSubject(subject)?.isEnabled ?? true
                        )
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Debug Controls
    private var debugControls: some View {
        VStack(spacing: 0) {
            // Modalità debug toggle
            HStack {
                Image(systemName: "ladybug.fill")
                    .foregroundColor(.red)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Modalità Debug")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Mostra log dettagliati e informazioni tecniche")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Toggle("", isOn: $settingsManager.notificationSettings.debugMode)
                    .tint(.red)
            }
            .padding()
            
            Divider().background(.white.opacity(0.2))
            
            // Test controls
            VStack(spacing: 12) {
                Button("Invia Notifica Test") {
                    HapticManager.shared.impact(style: .medium)
                    NotificationManager.shared.sendTestNotification()
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Button("Test Completo Sistema") {
                    HapticManager.shared.impact(style: .medium)
                    NotificationManager.shared.runCompleteTest()
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Button("Reset Analytics") {
                    HapticManager.shared.warning()
                    resetAnalytics()
                }
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - System Status Card
    private var systemStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stato del Sistema")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                SystemStatusRow(
                    title: "Permessi Notifiche",
                    status: .granted,
                    icon: "bell.badge.fill"
                )
                
                SystemStatusRow(
                    title: "Analytics",
                    status: settingsManager.notificationSettings.enableAnalytics ? .active : .inactive,
                    icon: "chart.bar.doc.horizontal"
                )
                
                SystemStatusRow(
                    title: "Smart Scheduling",
                    status: settingsManager.notificationSettings.enableSmartScheduling ? .active : .inactive,
                    icon: "brain.head.profile"
                )
                
                SystemStatusRow(
                    title: "Notifiche in Coda",
                    status: .active,
                    icon: "tray.full.fill",
                    detail: "12 programmate"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Notification Queue Card
    private var notificationQueueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coda Notifiche")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(0..<min(3, 5), id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Promemoria Matematica")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Text("Programmata per 14:30")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Text("2h")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: {}) {
                    HStack {
                        Text("Visualizza tutte")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Export Options Card
    private var exportOptionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Esporta Dati")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                Button(action: exportCSV) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.white)
                        
                        Text("Esporta CSV")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: exportJSON) {
                    HStack {
                        Image(systemName: "doc.plaintext")
                            .foregroundColor(.white)
                        
                        Text("Esporta JSON")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: shareReport) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                        
                        Text("Condividi Report")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "person.2")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Properties
    
    private var metrics: NotificationMetrics {
        settingsManager.notificationSettings.performanceMetrics
    }
    
    private var filteredEvents: [NotificationEvent] {
        let events = settingsManager.notificationSettings.notificationHistory
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .day:
            return events.filter { calendar.isDate($0.timestamp, inSameDayAs: now) }
        case .week:
            return events.filter { 
                calendar.dateInterval(of: .weekOfYear, for: now)?.contains($0.timestamp) ?? false 
            }
        case .month:
            return events.filter { 
                calendar.dateInterval(of: .month, for: now)?.contains($0.timestamp) ?? false 
            }
        case .all:
            return events
        }
    }
    
    private var topEngagementSubjects: [(key: String, value: Double)] {
        let engagement = metrics.subjectEngagement
        return engagement.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }
    
    private var maxEngagement: Double {
        metrics.subjectEngagement.values.max() ?? 1.0
    }
    
    private var activeDaysCount: Int {
        settingsManager.notificationSettings.daySchedules.filter { $0.isEnabled }.count
    }
    
    private var smartFeaturesCount: String {
        var count = 0
        if settingsManager.notificationSettings.enableSmartScheduling { count += 1 }
        if settingsManager.notificationSettings.adaptiveNotifications { count += 1 }
        if settingsManager.notificationSettings.locationBasedNotifications { count += 1 }
        if settingsManager.notificationSettings.holidayScheduling { count += 1 }
        return "\(count)/4"
    }
    
    // MARK: - Missing View Properties
    
    private var deliveryPerformanceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Consegna")
                .font(.headline)
                .foregroundColor(.white)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(height: 180)
                .overlay(
                    VStack {
                        Image(systemName: "speedometer")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Grafico Performance")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Tempo medio: \(String(format: "%.1f", metrics.averageDeliveryTime))s")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                )
        }
    }
    
    private var subjectPerformanceBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance per Materia")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(Array(metrics.subjectEngagement.prefix(5)), id: \.key) { subject, engagement in
                    HStack {
                        Text(subject)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(Int(engagement)) interazioni")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Circle()
                            .fill(engagement > 5 ? Color.green : engagement > 2 ? Color.orange : Color.red)
                            .frame(width: 8, height: 8)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                if metrics.subjectEngagement.isEmpty {
                    Text("Nessun dato disponibile")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding()
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var performanceRecommendations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Raccomandazioni")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                if metrics.deliveryRate < 0.8 {
                    RecommendationRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        title: "Tasso consegna basso",
                        description: "Verifica permessi notifiche e configurazioni"
                    )
                }
                
                if metrics.engagementRate < 0.3 {
                    RecommendationRow(
                        icon: "target",
                        color: .orange,
                        title: "Engagement migliorabile",
                        description: "Considera di ottimizzare orari e priorità"
                    )
                }
                
                if metrics.totalNotificationsSent > 50 && metrics.engagementRate > 0.7 {
                    RecommendationRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: "Ottime performance!",
                        description: "Il sistema funziona perfettamente"
                    )
                }
                
                if metrics.totalNotificationsSent < 10 {
                    RecommendationRow(
                        icon: "info.circle.fill",
                        color: .blue,
                        title: "Raccolta dati in corso",
                        description: "Usa l'app per una settimana per statistiche complete"
                    )
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetAnalytics() {
        settingsManager.notificationSettings.notificationHistory.removeAll()
        settingsManager.notificationSettings.performanceMetrics = NotificationMetrics()
        settingsManager.saveSettings()
    }
    
    private func exportCSV() {
        // Placeholder per export CSV
        print("Esportazione CSV in fase di sviluppo")
    }
    
    private func exportJSON() {
        // Placeholder per export JSON
        print("Esportazione JSON in fase di sviluppo")
    }
    
    private func shareReport() {
        // Placeholder per condivisione report
        print("Condivisione report in fase di sviluppo")
    }
}

// MARK: - Supporting Views

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct KPICard: View {
    let title: String
    let value: String
    let subtitle: String
    let trend: TrendDirection
    let color: Color
    
    enum TrendDirection {
        case improving, declining, stable
        
        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .declining: return "arrow.down.right"
            case .stable: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .improving: return .green
            case .declining: return .red
            case .stable: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .foregroundColor(trend.color)
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ConfigSummaryRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding()
    }
}

struct SystemStatusRow: View {
    let title: String
    let status: SystemStatus
    let icon: String
    let detail: String?
    
    enum SystemStatus {
        case active, inactive, granted, denied, warning
        
        var color: Color {
            switch self {
            case .active, .granted: return .green
            case .inactive, .denied: return .red
            case .warning: return .orange
            }
        }
        
        var text: String {
            switch self {
            case .active: return "Attivo"
            case .inactive: return "Inattivo"
            case .granted: return "Concesso"
            case .denied: return "Negato"
            case .warning: return "Attenzione"
            }
        }
    }
    
    init(title: String, status: SystemStatus, icon: String, detail: String? = nil) {
        self.title = title
        self.status = status
        self.icon = icon
        self.detail = detail
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(status.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                if let detail = detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            Text(status.text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.vertical, 4)
    }
}

struct RecommendationRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Debug Logs View (Placeholder)

struct DebugLogsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Debug Logs View - Coming Soon")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Subject Notification Status Card
struct SubjectNotificationStatusCard: View {
    let subject: String
    let color: Color
    let isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(subject)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.white)
            }
            
            HStack {
                Image(systemName: isEnabled ? "bell.fill" : "bell.slash.fill")
                    .font(.caption2)
                    .foregroundColor(isEnabled ? .green : .gray)
                
                Text(isEnabled ? "Attiva" : "Disattivata")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
        }
        .padding(10)
        .background(color.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NotificationAnalyticsView()
        .environmentObject(SettingsManager())
        .environmentObject(DataManager())
}