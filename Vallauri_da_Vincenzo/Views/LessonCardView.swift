//
//  LessonCardView.swift
//  OrarioScuolaApp
//

import SwiftUI

struct LessonCardView: View {
    let lesson: Lesson
    @State private var isPressed = false

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
                // Lesson card style
                RoundedRectangle(cornerRadius: 25)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: lesson.color).opacity(0.6), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                    .shadow(color: Color(hex: lesson.color).opacity(0.3), radius: 10, x: 0, y: 5)
            }

            HStack {
                // Left accent bar (different for breaks)
                if lesson.subject == "Intervallo" {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.gray.opacity(0.6))
                        .frame(width: 4)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: lesson.color))
                        .frame(width: 6)
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Subject and time
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
                            Text(lesson.subject)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("\(lesson.startTime) - \(lesson.endTime)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(lesson.subject == "Intervallo" ? .gray : .white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(lesson.subject == "Intervallo" ? Color.gray.opacity(0.2) : Color.white.opacity(0.1))
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

                    // Duration badge and break activities
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
                        }
                        
                        Spacer()
                        
                        Text("\(lesson.duration) min")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(lesson.subject == "Intervallo" ? .gray : .white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(lesson.subject == "Intervallo" ? Color.gray.opacity(0.3) : Color(hex: lesson.color).opacity(0.8))
                            .clipShape(Capsule())
                    }
                }
                .padding(.leading, 4)
            }
            .padding()
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
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
