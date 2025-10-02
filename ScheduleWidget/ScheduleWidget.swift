import WidgetKit
import SwiftUI

// MARK: - Lezione modello completo per Widget
struct WidgetLesson: Codable, Identifiable {
    let id: String
    let subject: String
    let teacher: String
    let classroom: String
    let dayOfWeek: Int // 1 = Lunedì, 2 = Martedì, etc.
    let startTime: String // "07:50"
    let endTime: String // "08:50"
    let color: String
    
    init(id: String = UUID().uuidString, subject: String, teacher: String, classroom: String, dayOfWeek: Int, startTime: String, endTime: String, color: String) {
        self.id = id
        self.subject = subject
        self.teacher = teacher
        self.classroom = classroom
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.color = color
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), lesson: WidgetLesson(subject: "Matematica", teacher: "GARRO V.", classroom: "T64 (28)", dayOfWeek: 5, startTime: "09:45", endTime: "10:40", color: "#ef5350"))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), lesson: getNextLesson())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        // Timeline aggiornata ogni 15 minuti per accuratezza
        for minuteOffset in 0 ..< 8 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset * 15, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, lesson: getNextLesson(at: entryDate))
            entries.append(entry)
        }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    // MARK: - Logica dinamica per trovare la prossima lezione
    func getNextLesson(at date: Date = Date()) -> WidgetLesson {
        let lessons = loadLessons()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        let currentHour = calendar.component(.hour, from: date)
        let currentMinute = calendar.component(.minute, from: date)
        
        // Converte da sistema domenica=1 a lunedì=1
        let currentDayOfWeek = currentWeekday == 1 ? 7 : currentWeekday - 1
        
        // Cerca lezioni per oggi che non sono ancora terminate
        let todayLessons = lessons.filter { $0.dayOfWeek == currentDayOfWeek }
            .sorted { $0.startTime < $1.startTime }

        let currentTimeMinutes = currentHour * 60 + currentMinute

        // Prima controlla se c'è una lezione in corso
        for lesson in todayLessons {
            guard let lessonStartMinutes = timeToMinutes(lesson.startTime),
                  let lessonEndMinutes = timeToMinutes(lesson.endTime) else {
                continue
            }

            // Lezione in corso - restituiamo la lezione senza modifiche
            if currentTimeMinutes >= lessonStartMinutes && currentTimeMinutes < lessonEndMinutes {
                return lesson
            }
        }

        // Poi cerca la prossima lezione di oggi
        for lesson in todayLessons {
            guard let lessonStartMinutes = timeToMinutes(lesson.startTime),
                  let lessonEndMinutes = timeToMinutes(lesson.endTime) else {
                continue
            }

            if lessonStartMinutes > currentTimeMinutes {
                return lesson
            }
        }

        // Se non ci sono lezioni rimaste oggi, cerca il prossimo giorno con lezioni
        for dayOffset in 1...7 {
            let nextDay = (currentDayOfWeek + dayOffset - 1) % 7 + 1
            let nextDayLessons = lessons.filter { $0.dayOfWeek == nextDay }
                .sorted { $0.startTime < $1.startTime }

            if let firstLesson = nextDayLessons.first {
                return WidgetLesson(
                    id: firstLesson.id,
                    subject: "⏳ " + firstLesson.subject,
                    teacher: firstLesson.teacher,
                    classroom: firstLesson.classroom + " (" + dayNameForDayOfWeek(nextDay) + ")",
                    dayOfWeek: firstLesson.dayOfWeek,
                    startTime: firstLesson.startTime,
                    endTime: firstLesson.endTime,
                    color: firstLesson.color
                )
            }
        }
        
        // Fallback
        return WidgetLesson(subject: "✅ Nessuna lezione", teacher: "", classroom: "Buone vacanze! 🎉", dayOfWeek: 1, startTime: "00:00", endTime: "00:00", color: "#4caf50")
    }
    
    private func dayNameForDayOfWeek(_ dayOfWeek: Int) -> String {
        switch dayOfWeek {
        case 1: return "Lun"
        case 2: return "Mar"
        case 3: return "Mer"
        case 4: return "Gio"
        case 5: return "Ven"
        case 6: return "Sab"
        case 7: return "Dom"
        default: return ""
        }
    }
    
    private func loadLessons() -> [WidgetLesson] {
        // Carica i dati dall'UserDefaults condiviso con l'app principale
        if let sharedDefaults = UserDefaults(suiteName: "group.vallauri.schedule"),
           let data = sharedDefaults.data(forKey: "SavedLessons"),
           let lessons = try? JSONDecoder().decode([WidgetLesson].self, from: data) {
            return lessons
        }
        
        // Fallback ai dati di esempio se non ci sono dati salvati
        return sampleLessons
    }
    
    private func isIntervallesson(_ lesson: WidgetLesson) -> Bool {
        return lesson.subject == "Intervallo"
    }
    
    private func timeToMinutes(_ time: String) -> Int? {
        let components = time.components(separatedBy: ":")
        guard components.count == 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else { return nil }
        return hours * 60 + minutes
    }
    
    private var sampleLessons: [WidgetLesson] {
        [
            //LUNEDI
        //LUNEDI
WidgetLesson(subject: "Inglese", teacher: "FOGLIA P.", classroom: "LAB.134 TELECOMUNICAZIONI (50)", dayOfWeek: 1, startTime: "07:50", endTime: "08:50", color: "#42a5f5"),
WidgetLesson(subject: "Sistemi e reti", teacher: "CANONICO T.", classroom: "LAB.134 TELECOMUNICAZIONI (50)", dayOfWeek: 1, startTime: "08:50", endTime: "09:45", color: "#66bb6a"),
WidgetLesson(subject: "Informatica", teacher: "BONAVIA M.", classroom: "LAB.119A PASCAL (27)", dayOfWeek: 1, startTime: "09:45", endTime: "10:40", color: "#7e57c2"),
WidgetLesson(subject: "Informatica", teacher: "BONAVIA M.", classroom: "LAB.119A PASCAL (27)", dayOfWeek: 1, startTime: "11:00", endTime: "11:55", color: "#7e57c2"),
WidgetLesson(subject: "T.P.S.I.T.", teacher: "FEA D., RACCA M.", classroom: "LAB.119B EULERO (25)", dayOfWeek: 1, startTime: "11:55", endTime: "13:40", color: "#ffa726"),

//MARTEDI
WidgetLesson(subject: "Religione", teacher: "CAVALLERO L.", classroom: "T31 (24)", dayOfWeek: 2, startTime: "07:50", endTime: "08:45", color: "#fbc02d"),
WidgetLesson(subject: "Inglese", teacher: "FOGLIA P.", classroom: "T31 (24)", dayOfWeek: 2, startTime: "08:45", endTime: "09:35", color: "#42a5f5"),
WidgetLesson(subject: "Matematica", teacher: "GARRO V.", classroom: "T31 (24)", dayOfWeek: 2, startTime: "09:35", endTime: "10:25", color: "#ef5350"),
WidgetLesson(subject: "T.P.S.I.T.", teacher: "FEA D., RACCA M.", classroom: "LAB.143 TURING (22)", dayOfWeek: 2, startTime: "10:30", endTime: "11:20", color: "#ffa726"),
WidgetLesson(subject: "Italiano", teacher: "CARANTA P.", classroom: "301 (28)", dayOfWeek: 2, startTime: "11:20", endTime: "12:10", color: "#8d6e63"),
WidgetLesson(subject: "Ginnastica", teacher: "BALLATORE A.", classroom: "PALESTRA", dayOfWeek: 2, startTime: "12:20", endTime: "14:00", color: "#ff7043"),

//MERCOLEDI
WidgetLesson(subject: "Informatica", teacher: "BONAVIA M., MAGGIORE G.", classroom: "LAB.S22 ARCHIMEDE (26)", dayOfWeek: 3, startTime: "07:50", endTime: "09:45", color: "#7e57c2"),
WidgetLesson(subject: "Storia", teacher: "CARANTA P.", classroom: "148 (28)", dayOfWeek: 3, startTime: "09:45", endTime: "10:40", color: "#6d4c41"),
WidgetLesson(subject: "Storia", teacher: "CARANTA P.", classroom: "148 (28)", dayOfWeek: 3, startTime: "11:00", endTime: "11:55", color: "#6d4c41"),
WidgetLesson(subject: "Sistemi e reti", teacher: "CANONICO T.", classroom: "LAB.116 LAPLACE (25)", dayOfWeek: 3, startTime: "11:55", endTime: "12:50", color: "#66bb6a"),
WidgetLesson(subject: "T.P.S.I.T.", teacher: "FEA D.", classroom: "LAB.116 LAPLACE (25)", dayOfWeek: 3, startTime: "12:50", endTime: "13:40", color: "#ffa726"),

//GIOVEDI
WidgetLesson(subject: "Italiano", teacher: "CARANTA P.", classroom: "212 TEST (24)", dayOfWeek: 4, startTime: "07:50", endTime: "09:35", color: "#8d6e63"),
WidgetLesson(subject: "Matematica", teacher: "GARRO V.", classroom: "212 TEST (24)", dayOfWeek: 4, startTime: "09:35", endTime: "10:25", color: "#ef5350"),
WidgetLesson(subject: "T.P.S.I.T.", teacher: "FEA D.", classroom: "LAB.116 LAPLACE (25)", dayOfWeek: 4, startTime: "10:30", endTime: "11:20", color: "#ffa726"),
WidgetLesson(subject: "Sistemi e reti", teacher: "CANONICO T., MAGGIORE G., CISCO", classroom: "LAB.S18 MARCONI (24)", dayOfWeek: 4, startTime: "11:20", endTime: "12:10", color: "#66bb6a"),
WidgetLesson(subject: "Sistemi e reti", teacher: "CANONICO T., MAGGIORE G., CISCO", classroom: "LAB.S18 MARCONI (24)", dayOfWeek: 4, startTime: "12:20", endTime: "13:10", color: "#66bb6a"),
WidgetLesson(subject: "Inglese", teacher: "FOGLIA P.", classroom: "T65 TEST (27)", dayOfWeek: 4, startTime: "13:10", endTime: "14:00", color: "#42a5f5"),

//VENERDI
WidgetLesson(subject: "Informatica", teacher: "BONAVIA M.", classroom: "LAB.119B EULERO (25)", dayOfWeek: 5, startTime: "07:50", endTime: "08:50", color: "#7e57c2"),
WidgetLesson(subject: "Italiano", teacher: "CARANTA P.", classroom: "T64 (28)", dayOfWeek: 5, startTime: "08:50", endTime: "09:45", color: "#8d6e63"),
WidgetLesson(subject: "Matematica", teacher: "GARRO V.", classroom: "T64 (28)", dayOfWeek: 5, startTime: "09:45", endTime: "10:40", color: "#ef5350"),
WidgetLesson(subject: "Gestione progetto", teacher: "FEA D., MAGGIORE G.", classroom: "LAB.T59 PLC (24)", dayOfWeek: 5, startTime: "11:00", endTime: "13:40", color: "#26a69a"),
        ]
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let lesson: WidgetLesson
}

struct ScheduleWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall, .systemMedium:
                mainWidgetView
            case .accessoryRectangular:
                accessoryRectangularView
            case .accessoryCircular:
                accessoryCircularView
            default:
                mainWidgetView
            }
        }
        .containerBackground(for: .widget) {
            // Liquid glass background
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: entry.lesson.color).opacity(0.15),
                        Color(hex: entry.lesson.color).opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blur(radius: 12)
                
                // Glass overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
            }
        }
    }
    
    private var mainWidgetView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(isCurrentLesson ? "▶️ In Corso" : "📚 Prossima Lezione")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isCurrentLesson ? Color(hex: entry.lesson.color) : .secondary)
                Spacer()
                Text(timeUntil)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: entry.lesson.color))
            }
            
            Text(entry.lesson.subject)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            if !entry.lesson.teacher.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(Color(hex: entry.lesson.color))
                        .font(.caption)
                    Text(entry.lesson.teacher)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(Color(hex: entry.lesson.color))
                    .font(.caption)
                Text("\(entry.lesson.startTime) - \(entry.lesson.endTime)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .foregroundStyle(Color(hex: entry.lesson.color))
                    .font(.caption)
                Text(entry.lesson.classroom)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
    }
    
    private var isCurrentLesson: Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentDayOfWeek = currentWeekday == 1 ? 7 : currentWeekday - 1
        
        guard entry.lesson.dayOfWeek == currentDayOfWeek else { return false }
        
        if let startMinutes = timeToMinutes(entry.lesson.startTime),
           let endMinutes = timeToMinutes(entry.lesson.endTime) {
            let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        }
        
        return false
    }
    
    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.lesson.subject)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(1)
            Text("\(entry.lesson.startTime) - \(entry.lesson.endTime)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.lesson.classroom)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }
    
    private var accessoryCircularView: some View {
        VStack(spacing: 1) {
            Text("📚")
                .font(.title3)
            Text(entry.lesson.startTime)
                .font(.caption2)
                .fontWeight(.bold)
        }
    }
    
    private var timeUntil: String {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentDayOfWeek = currentWeekday == 1 ? 7 : currentWeekday - 1
        
        // Se è oggi
        if entry.lesson.dayOfWeek == currentDayOfWeek {
            if let startMinutes = timeToMinutes(entry.lesson.startTime),
               let endMinutes = timeToMinutes(entry.lesson.endTime) {
                let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
                let minutesUntil = startMinutes - currentMinutes
                
                if minutesUntil > 0 {
                    if minutesUntil < 60 {
                        return "tra \(minutesUntil)m"
                    } else {
                        let hours = minutesUntil / 60
                        let minutes = minutesUntil % 60
                        return minutes > 0 ? "tra \(hours)h \(minutes)m" : "tra \(hours)h"
                    }
                } else if endMinutes > currentMinutes {
                    return "in corso"
                }
            }
        }
        
        return dayName(for: entry.lesson.dayOfWeek)
    }
    
    private func timeToMinutes(_ time: String) -> Int? {
        let components = time.components(separatedBy: ":")
        guard components.count == 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else { return nil }
        return hours * 60 + minutes
    }
    
    private func dayName(for dayOfWeek: Int) -> String {
        switch dayOfWeek {
        case 1: return "Lun"
        case 2: return "Mar"
        case 3: return "Mer"
        case 4: return "Gio"
        case 5: return "Ven"
        case 6: return "Sab"
        case 7: return "Dom"
        default: return ""
        }
    }
}

// Color extension per i widget
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
            (a, r, g, b) = (1, 1, 1, 0)
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

// MARK: - Current Lesson Countdown Provider
struct CurrentLessonProvider: TimelineProvider {
    func placeholder(in context: Context) -> CurrentLessonEntry {
        CurrentLessonEntry(
            date: Date(),
            lesson: WidgetLesson(subject: "Matematica", teacher: "GARRO V.", classroom: "T64 (28)", dayOfWeek: 5, startTime: "09:45", endTime: "10:40", color: "#ef5350"),
            timeRemaining: 25
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CurrentLessonEntry) -> ()) {
        let entry = getCurrentLessonEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CurrentLessonEntry>) -> ()) {
        var entries: [CurrentLessonEntry] = []
        let currentDate = Date()
        
        // Aggiornamento ogni minuto per il countdown
        for minuteOffset in 0 ..< 60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = getCurrentLessonEntry(at: entryDate)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func getCurrentLessonEntry(at date: Date = Date()) -> CurrentLessonEntry {
        let lessons = loadLessonsForCountdown()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        let currentHour = calendar.component(.hour, from: date)
        let currentMinute = calendar.component(.minute, from: date)
        
        let currentDayOfWeek = currentWeekday == 1 ? 7 : currentWeekday - 1
        let currentTimeMinutes = currentHour * 60 + currentMinute
        
        // Cerca la lezione attualmente in corso
        let todayLessons = lessons.filter { $0.dayOfWeek == currentDayOfWeek && !isIntervallesson($0) }
        
        for lesson in todayLessons {
            if let startMinutes = timeToMinutes(lesson.startTime),
               let endMinutes = timeToMinutes(lesson.endTime),
               currentTimeMinutes >= startMinutes && currentTimeMinutes < endMinutes {
                
                let remainingMinutes = endMinutes - currentTimeMinutes
                return CurrentLessonEntry(date: date, lesson: lesson, timeRemaining: remainingMinutes)
            }
        }
        
        // Nessuna lezione in corso - trova la prossima
        for lesson in todayLessons.sorted(by: { $0.startTime < $1.startTime }) {
            if let startMinutes = timeToMinutes(lesson.startTime),
               startMinutes > currentTimeMinutes {
                let minutesToStart = startMinutes - currentTimeMinutes
                return CurrentLessonEntry(date: date, lesson: lesson, timeRemaining: -minutesToStart) // Negativo indica "tra X minuti"
            }
        }
        
        // Fallback
        let fallbackLesson = WidgetLesson(subject: "Nessuna lezione", teacher: "", classroom: "Giornata finita!", dayOfWeek: currentDayOfWeek, startTime: "00:00", endTime: "00:00", color: "#9e9e9e")
        return CurrentLessonEntry(date: date, lesson: fallbackLesson, timeRemaining: 0)
    }
    
    private func loadLessonsForCountdown() -> [WidgetLesson] {
        if let sharedDefaults = UserDefaults(suiteName: "group.vallauri.schedule"),
           let data = sharedDefaults.data(forKey: "SavedLessons"),
           let lessons = try? JSONDecoder().decode([WidgetLesson].self, from: data) {
            return lessons
        }
        return sampleLessonsForCountdown
    }
    
    private func isIntervallesson(_ lesson: WidgetLesson) -> Bool {
        return lesson.subject == "Intervallo"
    }
    
    private func timeToMinutes(_ time: String) -> Int? {
        let components = time.components(separatedBy: ":")
        guard components.count == 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else { return nil }
        return hours * 60 + minutes
    }
    
    private var sampleLessonsForCountdown: [WidgetLesson] {
        [
            WidgetLesson(subject: "Matematica", teacher: "GARRO V.", classroom: "T64", dayOfWeek: 5, startTime: "09:45", endTime: "10:40", color: "#ef5350"),
            WidgetLesson(subject: "Informatica", teacher: "BONAVIA M.", classroom: "LAB.119B", dayOfWeek: 5, startTime: "07:50", endTime: "08:50", color: "#7e57c2")
        ]
    }
}

struct CurrentLessonEntry: TimelineEntry {
    let date: Date
    let lesson: WidgetLesson
    let timeRemaining: Int // Minuti rimanenti (negativo se la lezione deve iniziare)
}

struct CurrentLessonWidgetView: View {
    var entry: CurrentLessonProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                countdownSmallView
            case .systemMedium:
                countdownMediumView
            case .accessoryRectangular:
                countdownAccessoryView
            case .accessoryCircular:
                countdownCircularView
            default:
                countdownSmallView
            }
        }
        .containerBackground(for: .widget) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: entry.lesson.color).opacity(0.2),
                        Color(hex: entry.lesson.color).opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blur(radius: 8)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(0.9)
            }
        }
    }
    
    private var countdownSmallView: some View {
        VStack(spacing: 4) {
            HStack {
                Text(entry.timeRemaining >= 0 ? "⏰ Termina in" : "🕒 Inizia in")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Text("\(abs(entry.timeRemaining))")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: entry.lesson.color))
            
            Text(abs(entry.timeRemaining) == 1 ? "minuto" : "minuti")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text(entry.lesson.subject)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding()
    }
    
    private var countdownMediumView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.timeRemaining >= 0 ? "⏰ Lezione in corso" : "🕒 Prossima lezione")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Text(entry.lesson.subject)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                if !entry.lesson.teacher.isEmpty {
                    Text("Prof. \(entry.lesson.teacher)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(entry.lesson.classroom)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(entry.timeRemaining >= 0 ? "Termina in" : "Inizia in")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("\(abs(entry.timeRemaining))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: entry.lesson.color))
                
                Text(abs(entry.timeRemaining) == 1 ? "min" : "min")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
    
    private var countdownAccessoryView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.lesson.subject)
                    .font(.caption)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Text(entry.timeRemaining >= 0 ? "Termina in \(abs(entry.timeRemaining))'" : "Inizia in \(abs(entry.timeRemaining))'")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
    private var countdownCircularView: some View {
        VStack(spacing: 1) {
            Text(entry.timeRemaining >= 0 ? "⏰" : "🕒")
                .font(.caption)
            Text("\(abs(entry.timeRemaining))")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }
}

struct ScheduleWidget: Widget {
    let kind: String = "ScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ScheduleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prossima Lezione")
        .description("Mostra la prossima lezione della giornata.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

struct CurrentLessonWidget: Widget {
    let kind: String = "CurrentLessonWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CurrentLessonProvider()) { entry in
            CurrentLessonWidgetView(entry: entry)
        }
        .configurationDisplayName("Countdown Lezione")
        .description("Mostra quanto manca alla fine della lezione corrente.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

#Preview(as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    SimpleEntry(date: .now, lesson: WidgetLesson(subject: "Matematica", teacher: "GARRO V.", classroom: "T64 (28)", dayOfWeek: 5, startTime: "09:45", endTime: "10:40", color: "#ef5350"))
    SimpleEntry(date: .now, lesson: WidgetLesson(subject: "Inglese", teacher: "FOGLIA P.", classroom: "LAB.134 TELECOMUNICAZIONI", dayOfWeek: 1, startTime: "11:00", endTime: "11:55", color: "#42a5f5"))
}
