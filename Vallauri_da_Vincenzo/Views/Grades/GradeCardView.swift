//
//  GradeCardView.swift
//  Orario Vallauri
//
//  Created by Raffaele Vitale on 25/09/25.
//

import SwiftUI

struct GradeCardView: View {
    let grade: Grade
    @State private var isPressed = false
    @State private var showingEditGrade = false
    @State private var showingDeleteAlert = false
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ZStack {
            // Background con stile simile a LessonCardView
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: grade.color), Color(hex: grade.color).opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color(hex: grade.color).opacity(0.3), radius: 10, x: 0, y: 5)
            
            HStack {
                // Barra laterale con colore della materia
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: grade.color))
                    .frame(width: 6)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Header con materia e voto
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(grade.subject)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Prof. \(grade.teacher)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Voto con sfondo colorato
                        VStack(spacing: 2) {
                            Text(grade.formattedValue)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(grade.gradeJudgment)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: grade.gradeColor))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Descrizione del voto
                    Text(grade.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                    
                    // Data e statistiche
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(grade.date.formatted(.dateTime.day().month().locale(Locale(identifier: "it_IT"))))
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        // Badge con il tipo di valutazione
                        HStack(spacing: 4) {
                            Image(systemName: getIconForDescription(grade.description))
                                .font(.caption2)
                            Text(getShortType(from: grade.description))
                                .font(.caption2)
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                .padding(.leading, 4)
            }
            .padding()
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .contextMenu {
            Button {
                showingEditGrade = true
            } label: {
                Label("Modifica Voto", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Elimina Voto", systemImage: "trash")
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.9)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.9)) {
                    isPressed = false
                }
            }
        }
        .sheet(isPresented: $showingEditGrade) {
            EditGradeView(grade: grade)
                .environmentObject(dataManager)
        }
        .alert("Elimina Voto", isPresented: $showingDeleteAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Elimina", role: .destructive) {
                dataManager.deleteGrade(grade)
            }
        } message: {
            Text("Sei sicuro di voler eliminare questo voto?\n\n\(grade.subject) - \(grade.formattedValue)\n\(grade.description)")
        }
    }
    
    // Funzione per ottenere l'icona appropriata per il tipo di verifica
    private func getIconForDescription(_ description: String) -> String {
        let lowercased = description.lowercased()
        
        if lowercased.contains("verifica") || lowercased.contains("compito") {
            return "doc.text"
        } else if lowercased.contains("interrogazione") || lowercased.contains("orale") {
            return "person.wave.2"
        } else if lowercased.contains("laboratorio") || lowercased.contains("progetto") {
            return "laptopcomputer"
        } else if lowercased.contains("esercitazione") {
            return "pencil.and.outline"
        } else {
            return "checkmark.circle"
        }
    }
    
    // Funzione per ottenere una versione abbreviata del tipo di verifica
    private func getShortType(from description: String) -> String {
        let lowercased = description.lowercased()
        
        if lowercased.contains("verifica") {
            return "Verifica"
        } else if lowercased.contains("interrogazione") {
            return "Orale"
        } else if lowercased.contains("laboratorio") {
            return "Lab"
        } else if lowercased.contains("progetto") {
            return "Progetto"
        } else if lowercased.contains("esercitazione") {
            return "Esercizio"
        } else {
            return "Voto"
        }
    }
}

// Vista per mostrare la media di una materia
struct SubjectAverageCardView: View {
    let subjectGrades: SubjectGrades
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.thickMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: subjectGrades.color), Color(hex: subjectGrades.color).opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
                .shadow(color: Color(hex: subjectGrades.color).opacity(0.4), radius: 8, x: 0, y: 4)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subjectGrades.subject)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Prof. \(subjectGrades.teacher)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 8) {
                        Text("\(subjectGrades.gradeCount) vot\(subjectGrades.gradeCount == 1 ? "o" : "i")")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Circle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 3, height: 3)
                        
                        Text("Media: \(subjectGrades.formattedAverage)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Media grande
                VStack {
                    Text(subjectGrades.formattedAverage)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("MEDIA")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: subjectGrades.color).opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
        }
    }
}

#Preview {
    let mockGrade = Grade(
        subject: "Matematica",
        value: 8.5,
        date: Date(),
        description: "Verifica scritta",
        teacher: "GARRO V.",
        color: "#ef5350"
    )
    
    VStack(spacing: 15) {
        // Preview con voto
        GradeCardView(grade: mockGrade)
            .environmentObject(DataManager())
        
        // Preview della media materia (dati mock)
        SubjectAverageCardView(subjectGrades: SubjectGrades(
            subject: "Matematica",
            color: "#ef5350",
            teacher: "GARRO V.",
            grades: [mockGrade]
        ))
    }
    .padding()
    .background(Color.black)
}