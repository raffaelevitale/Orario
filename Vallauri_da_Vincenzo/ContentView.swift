import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var liveActivityTimer: Timer?

    var body: some View {
        TabView {
            SchoolScheduleView()
                .tabItem {
                    Image(systemName: "calendar.day.timeline.left")
                    Text("Orario")
                }
            
            WeeklyPlannerView()
                .tabItem {
                    Image(systemName: "calendar.badge.plus")
                    Text("Planner")
                }
            
            StudyTimerView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("Timer")
                }
            
            GradesView()
                .tabItem {
                    Image(systemName: "chart.bar.doc.horizontal")
                    Text("Voti")
                }
        }
        .background(.black)
        .onAppear {
            setupNotifications()
            setupTabBarAppearance()
            setupLiveActivities()
        }
        .onDisappear {
            liveActivityTimer?.invalidate()
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
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
}