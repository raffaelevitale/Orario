//
//  LessonCardView.swift
//  OrarioScuolaApp
//

import SwiftUI
import Combine

struct LessonCardView: View {
    let lesson: Lesson
    @EnvironmentObject var dataManager: DataManager
    @State private var isPressed = false
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    private var isCurrentLesson: Bool {
        dataManager.isCurrentLesson(lesson)
    }
    
    private var isNextLesson: Bool {
        dataManager.isNextLesson(lesson)
    }

    var body: some View {
        ZStack {
            // Background with different styles for lessons and breaks
            if lesson.subject == "Intervallo" {
                // Break card style
                RoundedRectangle(cornerRadius: 25)
                    .fill(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [.gray.opacity(0.4), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 3)
            } else {
                // Lesson card style with current lesson highlighting
                RoundedRectangle(cornerRadius: 25)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: isCurrentLesson ? 
                                        [Color(hex: lesson.color), Color(hex: lesson.color).opacity(0.3)] :
                                        [Color(hex: lesson.color).opacity(0.6), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isCurrentLesson ? 3 : 2
                            )
                    }
                    .shadow(
                        color: isCurrentLesson ? 
                            Color(hex: lesson.color).opacity(0.6) : 
                            Color(hex: lesson.color).opacity(0.3), 
                        radius: isCurrentLesson ? 15 : 10, 
                        x: 0, 
                        y: isCurrentLesson ? 8 : 5
                    )
                    .overlay {
                        // Pulsing effect for current lesson
                        if isCurrentLesson {
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color(hex: lesson.color), lineWidth: 2)
                                .opacity(0.8)
                                .scaleEffect(1.02)
                                .animation(
                                    .easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true),
                                    value: currentTime
                                )
                        }
                        
                        // Next lesson indicator
                        if isNextLesson && !isCurrentLesson {
                            VStack {
                                HStack {
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.badge.checkmark")
                                            .font(.caption)
                                        Text("Prossima")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(Color(hex: lesson.color))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: lesson.color).opacity(0.2))
                                    .clipShape(Capsule())
                                    .padding(.top, 12)
                                    .padding(.trailing, 16)
                                }
                                Spacer()
                            }
                        }
                    }
            }

            HStack {
                // Left accent bar (different for breaks and current lesson)
                if lesson.subject == "Intervallo" {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.gray.opacity(0.6))
                        .frame(width: 4)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: lesson.color))
                        .frame(width: isCurrentLesson ? 8 : 6)
                        .animation(.easeInOut(duration: 0.3), value: isCurrentLesson)
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Subject and time with current lesson indicator
                    HStack {
                        if lesson.subject == "Intervallo" {
                            HStack(spacing: 6) {
                                Image(systemName: "cup.and.saucer.fill")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                Text(lesson.subject)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            HStack(spacing: 8) {
                                if isCurrentLesson {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(Color(hex: lesson.color))
                                        .scaleEffect(1.1)
                                }
                                
                                Text(lesson.subject)
                                    .font(.headline)
                                    .fontWeight(isCurrentLesson ? .bold : .semibold)
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: isCurrentLesson ? "clock.fill" : "clock")
                                .font(.caption)
                            Text("\(lesson.startTime) - \(lesson.endTime)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(
                            lesson.subject == "Intervallo" ? 
                                .gray : 
                                (isCurrentLesson ? Color(hex: lesson.color) : .white.opacity(0.8))
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            lesson.subject == "Intervallo" ? 
                                Color.gray.opacity(0.2) : 
                                (isCurrentLesson ? 
                                    Color(hex: lesson.color).opacity(0.2) : 
                                    Color.white.opacity(0.1)
                                )
                        )
                        .clipShape(Capsule())
                    }

                    // Teacher (only for lessons, not breaks)
                    if lesson.subject != "Intervallo" && !lesson.teacher.isEmpty {
                        HStack {
                            Image(systemName: "person.circle")
                                .font(.caption)
                            Text(lesson.teacher)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }

                    // Classroom
                    HStack {
                        Image(systemName: "location.circle")
                            .font(.caption)
                        Text(lesson.classroom)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(lesson.subject == "Intervallo" ? .gray.opacity(0.8) : .white.opacity(0.9))

                    // Duration badge and break activities with current lesson progress
                    HStack {
                        if lesson.subject == "Intervallo" {
                            HStack(spacing: 4) {
                                Image(systemName: "figure.walk")
                                    .font(.caption2)
                                Text("Pausa")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.gray.opacity(0.7))
                        } else if isCurrentLesson {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform")
                                    .font(.caption2)
                                    .foregroundColor(Color(hex: lesson.color))
                                    .opacity(0.8)
                                Text("In corso")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: lesson.color))
                                
                                // Progress indicator
                                if let progress = getLessonProgress() {
                                    ProgressView(value: progress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: lesson.color)))
                                        .frame(width: 40, height: 4)
                                        .scaleEffect(y: 1.5)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(lesson.duration) min")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                lesson.subject == "Intervallo" ? 
                                    .gray : 
                                    (isCurrentLesson ? Color(hex: lesson.color) : .white)
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                lesson.subject == "Intervallo" ? 
                                    Color.gray.opacity(0.3) : 
                                    (isCurrentLesson ? 
                                        Color(hex: lesson.color).opacity(0.3) : 
                                        Color(hex: lesson.color).opacity(0.8)
                                    )
                            )
                            .clipShape(Capsule())
                    }
                }
                .padding(.leading, 4)
            }
            .padding()
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onTapGesture {
            withAnimation {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }

            // Different actions for lessons and breaks
            if lesson.subject == "Intervallo" {
                // Maybe show break activities or timer
                print("Break tapped: \(lesson.classroom)")
            } else {
                // Show lesson details or set reminder
                print("Lesson tapped: \(lesson.subject)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getLessonProgress() -> Double? {
        guard isCurrentLesson else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        
        guard let startMinutes = timeToMinutes(lesson.startTime),
              let endMinutes = timeToMinutes(lesson.endTime) else { return nil }
        
        let totalDuration = Double(endMinutes - startMinutes)
        let elapsed = Double(currentMinutes - startMinutes)
        
        return min(max(elapsed / totalDuration, 0), 1)
    }
    
    private func timeToMinutes(_ time: String) -> Int? {
        let components = time.components(separatedBy: ":")
        guard components.count == 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else { return nil }
        return hours * 60 + minutes
    }
}

// Color extension per hex colors
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    VStack(spacing: 15) {
        // Preview with lesson
        LessonCardView(lesson: Lesson.sampleData[0])
        
        // Preview with break
        LessonCardView(lesson: Lesson.breaks[0])
        
                // Another lesson
        if Lesson.sampleData.count > 1 {
            LessonCardView(lesson: Lesson.sampleData[1])
        }
    }
    .padding()
    .background(Color.black)
}
