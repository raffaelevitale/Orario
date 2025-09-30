//
//  NextLessonWidget.swift
//  OrarioScuolaApp
//

import WidgetKit
import SwiftUI

struct NextLessonProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextLessonEntry {
        NextLessonEntry(
            date: Date(),
            lesson: Lesson(
                subject: "Informatica",
                teacher: "BONAVIA M.",
                classroom: "LAB.S22 ARCHIMEDE",
                dayOfWeek: 1,
                startTime: "07:50",
                endTime: "08:50",
                color: "#7e57c2"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextLessonEntry) -> ()) {
        let entry = NextLessonEntry(
            date: Date(),
            lesson: getNextLesson()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextLessonEntry>) -> ()) {
        var entries: [NextLessonEntry] = []
        let currentDate = Date()

        // Aggiorna ogni 15 minuti
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset * 15, to: currentDate)!
            let entry = NextLessonEntry(
                date: entryDate,
                lesson: getNextLesson(for: entryDate)
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func getNextLesson(for date: Date = Date()) -> Lesson? {
        // Carica le lezioni salvate o usa quelle di default
        let lessons = loadLessons()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        let dayOfWeek = currentWeekday == 1 ? 7 : currentWeekday - 1

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTime = formatter.string(from: date)

        // Trova la prossima lezione di oggi
        let todayLessons = lessons.filter { $0.dayOfWeek == dayOfWeek }
            .sorted { $0.startTime < $1.startTime }

        for lesson in todayLessons {
            if lesson.startTime > currentTime {
                return lesson
            }
        }

        // Se non ci sono più lezioni oggi, cerca domani
        let tomorrow = dayOfWeek == 5 ? 1 : dayOfWeek + 1
        let tomorrowLessons = lessons.filter { $0.dayOfWeek == tomorrow }
            .sorted { $0.startTime < $1.startTime }

        return tomorrowLessons.first
    }

    private func loadLessons() -> [Lesson] {
        // In un'app reale, caricheresti da UserDefaults o Core Data
        return Lesson.sampleData
    }
}

struct NextLessonEntry: TimelineEntry {
    let date: Date
    let lesson: Lesson?
}

struct NextLessonWidget: Widget {
    let kind: String = "NextLessonWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextLessonProvider()) { entry in
            NextLessonWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prossima Lezione")
        .description("Mostra la tua prossima lezione")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NextLessonWidgetEntryView: View {
    var entry: NextLessonProvider.Entry

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.black, Color(hex: entry.lesson?.color ?? "#7e57c2").opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let lesson = entry.lesson {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("PROSSIMA")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        Text(lesson.startTime)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    Text(lesson.subject)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))

                            Text(lesson.teacher)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }

                        HStack {
                            Image(systemName: "location.circle.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))

                            Text(lesson.classroom)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                }
                .padding()
            } else {
                VStack {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.6))

                    Text("Nessuna lezione")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}
