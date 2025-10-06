//
//  Grade.swift
//  Orario Vallauri
//
//  Created by Raffaele Vitale on 25/09/25.
//

import Foundation

struct Grade: Identifiable, Codable, Equatable {
    let id: UUID
    let subject: String
    let value: Double // Voto (es. 7.5, 8.0, ecc.)
    let date: Date
    let description: String // Tipo di verifica (es. "Verifica scritta", "Interrogazione", "Laboratorio")
    let teacher: String
    let color: String // Colore della materia (preso dalle lezioni)
    
    init(subject: String, value: Double, date: Date, description: String, teacher: String, color: String) {
        self.id = UUID()
        self.subject = subject
        self.value = value
        self.date = date
        self.description = description
        self.teacher = teacher
        self.color = color
    }
    
    // Computed property per formattare il voto
    var formattedValue: String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    // Computed property per determinare il colore del voto basato sul valore
    var gradeColor: String {
        switch value {
        case 9...10:
            return "#4caf50" // Verde per voti eccellenti
        case 7..<9:
            return "#2196f3" // Blu per voti buoni
        case 6..<7:
            return "#ff9800" // Arancione per voti sufficienti
        case 4..<6:
            return "#ff5722" // Rosso-arancione per voti insufficienti
        default:
            return "#f44336" // Rosso per voti gravemente insufficienti
        }
    }
    
    // Computed property per il giudizio testuale
    var gradeJudgment: String {
        switch value {
        case 10:
            return "Eccellente"
        case 9..<10:
            return "Ottimo"
        case 8..<9:
            return "Distinto"
        case 7..<8:
            return "Buono"
        case 6..<7:
            return "Sufficiente"
        case 5..<6:
            return "Insufficiente"
        case 4..<5:
            return "Scarso"
        default:
            return "Gravemente Insufficiente"
        }
    }
    

}

// Struttura per raggruppare i voti per materia
struct SubjectGrades {
    let subject: String
    let color: String
    let teacher: String
    let grades: [Grade]
    
    // Media dei voti per questa materia
    var average: Double {
        guard !grades.isEmpty else { return 0.0 }
        return grades.reduce(0) { $0 + $1.value } / Double(grades.count)
    }
    
    // Formattazione della media
    var formattedAverage: String {
        if average == floor(average) {
            return String(format: "%.0f", average)
        } else {
            return String(format: "%.1f", average)
        }
    }
    
    // Numero di voti
    var gradeCount: Int {
        return grades.count
    }
}