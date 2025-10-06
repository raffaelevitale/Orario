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
        // Controllo iniziale delle Live Activities
        dataManager.checkAndManageLiveActivities()
        
        // Timer per aggiornare le Live Activities ogni minuto
        liveActivityTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            dataManager.checkAndManageLiveActivities()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)

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