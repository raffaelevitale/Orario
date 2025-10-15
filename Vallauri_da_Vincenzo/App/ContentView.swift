import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var settingsManager = SettingsManager()
    @State private var liveActivityTimer: Timer?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            SchoolScheduleView()
                .tabItem {
                    Image(systemName: "calendar.day.timeline.left")
                    Text("Orario")
                }
                .tag(1)
            
            WeeklyPlannerView()
                .tabItem {
                    Image(systemName: "calendar.badge.plus")
                    Text("Planner")
                }
                .tag(2)
            
            GradesView()
                .tabItem {
                    Image(systemName: "chart.bar.doc.horizontal")
                    Text("Voti")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Impostazioni")
                }
                .tag(4)
        }
        .environmentObject(settingsManager)
        .onAppear {
            setupNotifications()
            setupTabBarAppearance()
            setupLiveActivities()
            updateNavigationAppearance()
        }
        .onDisappear {
            liveActivityTimer?.invalidate()
        }
        .onChange(of: settingsManager.isCompactNavigation) { _ in
            updateNavigationAppearance()
            setupTabBarAppearance() // Aggiorna anche la tab bar
        }
        .onChange(of: selectedTab) { _ in
            HapticManager.shared.selection()
        }
        .onChange(of: settingsManager.backgroundColor) { _ in
            // Forza refresh quando cambia il background
            DispatchQueue.main.async {
                self.updateNavigationAppearance()
            }
        }
    }
    
    private func setupNotifications() {
        // Richiedi permessi notifiche all'avvio
        NotificationManager.shared.requestPermissions { granted in
            if granted {
                print("✅ Permessi notifiche concessi all'avvio!")
                dataManager.rescheduleNotifications()
            } else {
                print("❌ Permessi notifiche negati all'avvio!")
            }
        }
    }
    
    private func setupLiveActivities() {
        // TEMPORANEAMENTE DISABILITATO
        // Le Live Activities richiedono iOS 16.1+ e Widget Extension configurato
        // Errore: "unsupportedTarget" indica che il target non supporta Live Activities
        
        #if DEBUG
        print("⚠️ Live Activities disabilitate - richiede configurazione avanzata")
        print("   Vedi LIVE_ACTIVITIES_SETUP.md per istruzioni complete")
        #endif
        
        return
        
        /* CODICE ORIGINALE - DA RIABILITARE DOPO CONFIGURAZIONE
        // Controllo iniziale delle Live Activities
        dataManager.checkAndManageLiveActivities()
        
        // Timer per aggiornare le Live Activities ogni minuto
        liveActivityTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            dataManager.checkAndManageLiveActivities()
        }
        */
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // Configurazione modalità compatta
        if settingsManager.isCompactNavigation {
            // Icone più piccole senza testo
            let itemAppearance = UITabBarItemAppearance()
            
            // Nascondi il testo
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear, .font: UIFont.systemFont(ofSize: 0)]
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.clear, .font: UIFont.systemFont(ofSize: 0)]
            
            // Ridimensiona le icone (offset per centrarle meglio)
            itemAppearance.normal.iconColor = .white.withAlphaComponent(0.6)
            itemAppearance.selected.iconColor = .white
            
            // Applica l'aspetto agli item
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
        } else {
            // Modalità normale con testo
            let itemAppearance = UITabBarItemAppearance()
            
            itemAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.6),
                .font: UIFont.systemFont(ofSize: 10)
            ]
            itemAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
            
            itemAppearance.normal.iconColor = .white.withAlphaComponent(0.6)
            itemAppearance.selected.iconColor = .white
            
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func updateNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        
        if settingsManager.isCompactNavigation {
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor.clear
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        } else {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        }
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
}