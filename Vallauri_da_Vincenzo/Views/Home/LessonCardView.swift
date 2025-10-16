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
    @State private var isPulsing = false
    @State private var currentTime = Date()
    @State private var showLiveActivityAlert = false
    @State private var showLiveActivityToast = false
    
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
            if lesson.isBreak {
                // Break card style - molto più discreto
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                Color.gray.opacity(0.2),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .clear, radius: 0)
            } else {
                // Lesson card style with current lesson highlighting
                RoundedRectangle(cornerRadius: 25)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: isCurrentLesson ? 
                                        [Color(hex: lesson.color), Color(hex: lesson.color).opacity(0.5)] :
                                        [Color(hex: lesson.color).opacity(0.6), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isCurrentLesson ? 2.5 : 2
                            )
                    }
                    .shadow(
                        color: isCurrentLesson ? 
                            Color(hex: lesson.color).opacity(0.5) : 
                            Color(hex: lesson.color).opacity(0.3), 
                        radius: isCurrentLesson ? 12 : 10, 
                        x: 0, 
                        y: isCurrentLesson ? 6 : 5
                    )
                    .overlay {
                        // Pulsing effect for current lesson - animated
                        if isCurrentLesson {
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color(hex: lesson.color), lineWidth: 2)
                                .scaleEffect(isPulsing ? 1.03 : 1.0)
                                .opacity(isPulsing ? 0.3 : 0.7)
                                .animation(
                                    Animation.easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true),
                                    value: isPulsing
                                )
                                .onAppear {
                                    isPulsing = true
                                }
                        }
                        
                        // Next lesson indicator - più prominente
                        if isNextLesson && !isCurrentLesson {
                            VStack {
                                HStack {
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Text("Prossima")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .textCase(.uppercase)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: lesson.color))
                                    .clipShape(Capsule())
                                    .shadow(color: Color(hex: lesson.color).opacity(0.5), radius: 5, x: 0, y: 2)
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
                if lesson.isBreak {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.3))
                        .frame(width: 3)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: lesson.color))
                        .frame(width: isCurrentLesson ? 8 : 6)
                        .animation(.easeInOut(duration: 0.3), value: isCurrentLesson)
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Subject with current lesson indicator
                    HStack {
                        if lesson.isBreak {
                            HStack(spacing: 6) {
                                Image(systemName: "cup.and.saucer.fill")
                                    .font(.callout)
                                    .foregroundColor(.gray.opacity(0.6))
                                Text(lesson.subject.uppercased())
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                        } else {
                            HStack(spacing: 8) {
                                if isCurrentLesson {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(Color(hex: lesson.color))
                                        .scaleEffect(1.1)
                                }
                                
                                // Icona ? per lezioni incomplete
                                if lesson.hasIncompleteInfo {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.callout)
                                        .foregroundColor(.orange.opacity(0.7))
                                }
                                
                                Text(lesson.subject.isEmpty ? "Lezione" : lesson.subject)
                                    .font(.headline)
                                    .fontWeight(isCurrentLesson ? .bold : .semibold)
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                            }
                        }

                        Spacer()
                    }
                    
                    // Time - now in a separate row
                    HStack(spacing: 4) {
                        Image(systemName: isCurrentLesson ? "clock.fill" : "clock")
                            .font(.caption)
                        Text("\(lesson.startTime) - \(lesson.endTime)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(
                        lesson.isBreak ? 
                            .gray.opacity(0.6) : 
                            (isCurrentLesson ? Color(hex: lesson.color) : .white.opacity(0.8))
                    )
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        lesson.isBreak ? 
                            Color.gray.opacity(0.1) : 
                            (isCurrentLesson ? 
                                Color(hex: lesson.color).opacity(0.2) : 
                                Color.white.opacity(0.1)
                            )
                    )
                    .clipShape(Capsule())

                    // Teacher (only for lessons, not breaks)
                    if !lesson.isBreak && !lesson.teacher.isEmpty {
                        HStack {
                            Image(systemName: "person.circle")
                                .font(.caption)
                            Text(lesson.teacher)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    } else if !lesson.isBreak && lesson.teacher.isEmpty {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.caption)
                                .foregroundColor(.orange.opacity(0.6))
                            Text("Docente non specificato")
                                .font(.caption)
                                .italic()
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    // Classroom
                    if !lesson.isBreak {
                        HStack {
                            Image(systemName: lesson.classroom.isEmpty ? "questionmark.circle" : "location.circle")
                                .font(.caption)
                            Text(lesson.classroom.isEmpty ? "Aula non specificata" : lesson.classroom)
                                .font(.subheadline)
                                .fontWeight(lesson.classroom.isEmpty ? .regular : .medium)
                                .italic(lesson.classroom.isEmpty)
                        }
                        .foregroundColor(lesson.classroom.isEmpty ? .white.opacity(0.6) : .white.opacity(0.9))
                    }

                    // Duration badge and break activities with current lesson progress
                    HStack {
                        if lesson.isBreak {
                            HStack(spacing: 4) {
                                Image(systemName: "figure.walk")
                                    .font(.caption2)
                                Text("Pausa")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.gray.opacity(0.5))
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
                                
                                // Progress indicator with percentage
                                if let progress = getLessonProgress() {
                                    HStack(spacing: 4) {
                                        ProgressView(value: progress)
                                            .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: lesson.color)))
                                            .frame(width: 50, height: 4)
                                            .scaleEffect(y: 1.5)
                                        
                                        Text("\(Int(progress * 100))%")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(hex: lesson.color))
                                            .monospacedDigit()
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(lesson.duration) min")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                lesson.isBreak ? 
                                    .gray.opacity(0.5) : 
                                    (isCurrentLesson ? Color(hex: lesson.color) : .white)
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                lesson.isBreak ? 
                                    Color.gray.opacity(0.2) : 
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
            // Animazione di feedback
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }

            // Feedback aptico
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            // Different actions for lessons and breaks
            if lesson.isBreak {
                print("Break tapped: \(lesson.classroom)")
            } else {
                // Avvia Live Activity per questa lezione
                dataManager.startLiveActivity(for: lesson)
                
                // Mostra toast di conferma
                withAnimation(.easeInOut(duration: 0.3)) {
                    showLiveActivityToast = true
                }
                
                // Nasconde il toast dopo 2 secondi
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showLiveActivityToast = false
                    }
                }
                
                print("✅ Live Activity richiesta per: \(lesson.subject)")
            }
        }
        .overlay(
            // Toast notification per conferma Live Activity
            VStack {
                if showLiveActivityToast {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.white)
                        Text("Live Activity attivata")
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.green)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer()
            }
            .padding(.top, 8)
        )
        // Alert temporaneamente commentato
        /*
        .alert("Live Activity Avviata", isPresented: $showLiveActivityAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("La Live Activity per \(lesson.subject) è ora attiva nella Dynamic Island e Lock Screen.")
        }
        */
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
