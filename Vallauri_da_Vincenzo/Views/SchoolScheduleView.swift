import SwiftUI
import Combine

struct SchoolScheduleView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDay = SchoolScheduleView.dayIndexForToday()
    @State private var scrollOffset: CGFloat = 0
    @State private var currentDate = Date()

    private let days = [
        (1, "Lun"), (2, "Mar"), (3, "Mer"), (4, "Gio"), (5, "Ven")
    ]

    private static func dayIndexForToday() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        switch weekday {
        case 2: return 1 // Monday -> 1
        case 3: return 2 // Tuesday -> 2
        case 4: return 3 // Wednesday -> 3
        case 5: return 4 // Thursday -> 4
        case 6: return 5 // Friday -> 5
        case 7: return 5 // Saturday -> map to Friday
        default: return 1 // Sunday -> map to Monday
        }
    }

    private var collapseProgress: CGFloat {
        let t = min(max(scrollOffset / 120, 0), 1)
        return t
    }

    private var headerScale: CGFloat { 1.0 - 0.15 * collapseProgress }
    private var headerOpacity: Double { Double(1.0 - 0.3 * collapseProgress) }
    private var selectorScale: CGFloat { 1.0 - 0.2 * collapseProgress }
    private var selectorOpacity: Double { Double(1.0 - 0.2 * collapseProgress) }

    private struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
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

                VStack(spacing: 0) {

                    daySelector
                        .scaleEffect(selectorScale)
                        .opacity(selectorOpacity)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: collapseProgress)

                    lessonsView
                }
            }
            .navigationTitle(currentDate.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "it_IT"))).capitalized)
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                // Aggiorna la data ogni minuto per cambiare il titolo a mezzanotte
                let newDate = Date()
                if !Calendar.current.isDate(currentDate, inSameDayAs: newDate) {
                    currentDate = newDate
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Oggi") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDay = SchoolScheduleView.dayIndexForToday()
                        }
                    }
                    .foregroundColor(.white)
                    .opacity(selectedDay == SchoolScheduleView.dayIndexForToday() ? 0.5 : 1.0)
                    .disabled(selectedDay == SchoolScheduleView.dayIndexForToday())
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("🔔 Programma Notifiche") {
                            programmaNotifiche()
                        }
                        
                        Button("🧪 Test Notifica Lezione") {
                            if let firstLesson = dataManager.lessons.first(where: { $0.subject != "Intervallo" }) {
                                NotificationManager.shared.sendTestNotification(for: firstLesson)
                            }
                        }
                        
                        Button("⏰ Test Notifica Intervallo") {
                            if let firstBreak = dataManager.lessons.first(where: { $0.subject == "Intervallo" }) {
                                NotificationManager.shared.sendTestNotification(for: firstBreak)
                            }
                        }
                        
                        Divider()
                        
                        Button("📱 Gestisci Live Activity") {
                            dataManager.checkAndManageLiveActivities()
                        }
                        
                        Button("🔄 Aggiorna Widget") {
                            dataManager.forceWidgetUpdate()
                        }
                        
                        Button("🗑️ Cancella Notifiche Test") {
                            NotificationManager.shared.clearTestNotifications()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
    
    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(days, id: \.0) { day in
                    dayButton(dayNumber: day.0, dayName: day.1)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 15)
    }

    private func dayButton(dayNumber: Int, dayName: String) -> some View {
        Button(action: { selectedDay = dayNumber }) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedDay == dayNumber ? .white : .clear)
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )

                Text(dayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedDay == dayNumber ? .black : .white)
            }
            .contentShape(Rectangle())
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedDay)
    }

    private var lessonsView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                // Elemento invisibile per il reset dello scroll
                Color.clear
                    .frame(height: 1)
                    .id("top")
                
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("LESSONS_SCROLL")).minY)
                }
                .frame(height: 0)

                LazyVStack(spacing: 15) {
                    let lessonsForDay = dataManager.getLessonsForDay(selectedDay)
                    
                    if lessonsForDay.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(lessonsForDay) { lesson in
                            LessonCardView(lesson: lesson)
                                .id(lesson.id)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .coordinateSpace(name: "LESSONS_SCROLL")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .onChange(of: selectedDay) { _ in
                // Reset scroll position quando cambia il giorno
                withAnimation(.easeOut(duration: 0.5)) {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
    }

    private var emptyStateView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .frame(height: 200)

            VStack(spacing: 15) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.7))

                Text("Nessuna lezione")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("Non ci sono lezioni programmate per questo giorno")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 50)
    }

    private func dateForDay(_ dayNumber: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let mondayOffset = (todayWeekday == 1) ? -6 : 2 - todayWeekday

        guard let monday = calendar.date(byAdding: .day, value: mondayOffset, to: today) else {
            return today
        }

        return calendar.date(byAdding: .day, value: dayNumber - 1, to: monday) ?? today
    }
    
    private func programmaNotifiche() {
        NotificationManager.shared.requestPermissions { granted in
            if granted {
                dataManager.rescheduleNotifications()
                print("✅ Notifiche programmate!")
            } else {
                print("❌ Permessi negati!")
            }
        }
    }
}

#Preview {
    SchoolScheduleView()
        .environmentObject(DataManager())
}
