import SwiftUI
import Combine

struct SchoolScheduleView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedDay = SchoolScheduleView.dayIndexForToday()
    @State private var scrollOffset: CGFloat = 0
    @State private var currentDate = Date()
    @State private var scrollProxy: ScrollViewProxy?

    private let days = [
        (1, "Lun"), (2, "Mar"), (3, "Mer"), (4, "Gio"), (5, "Ven")
    ]
    
    // Timer per aggiornare più frequentemente
    private let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

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
                    colors: settingsManager.backgroundColor.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .onReceive(timer) { _ in
                // Aggiorna più frequentemente per la materia attuale
                currentDate = Date()
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
                
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        if let currentLesson = dataManager.getCurrentLesson() {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                scrollToCurrentLesson()
                            }
                        }
                    }) {
                        VStack(spacing: 2) {
                            Text("Orario Scolastico")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            if let currentLesson = dataManager.getCurrentLesson() {
                                HStack(spacing: 4) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.caption2)
                                    Text("\(currentLesson.subject) • \(currentLesson.endTime)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(Color(hex: currentLesson.color))
                            } else {
                                VStack(spacing: 1) {
                                    Text(currentDate.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "it_IT"))).capitalized)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(currentDate.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "it_IT"))))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
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
                .padding(.bottom, 20)
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
            .onAppear {
                scrollProxy = proxy
            }
        }
    }
    
    private func scrollToCurrentLesson() {
        guard let currentLesson = dataManager.getCurrentLesson(),
              let proxy = scrollProxy else { return }
        
        // Cambia al giorno corrente se necessario
        let todayIndex = SchoolScheduleView.dayIndexForToday()
        if selectedDay != todayIndex {
            selectedDay = todayIndex
        }
        
        // Aspetta un momento per il cambio di giorno e poi scrolla
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                proxy.scrollTo(currentLesson.id, anchor: .center)
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
}

// Color extension per hex colors (se non già presente)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    SchoolScheduleView()
        .environmentObject(DataManager())
}
