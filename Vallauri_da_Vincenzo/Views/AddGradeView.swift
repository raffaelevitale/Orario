//
//  AddGradeView.swift
//  Orario Vallauri
//
//  Created by Raffaele Vitale on 25/09/25.
//

import SwiftUI

struct AddGradeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var selectedSubject = ""
    @State private var gradeValue: Double = 6.0
    @State private var description = ""
    @State private var selectedDate = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let gradeDescriptions = [
        "Verifica scritta",
        "Interrogazione orale",
        "Compito in classe",
        "Progetto",
        "Laboratorio",
        "Esercitazione",
        "Tesina",
        "Presentazione",
        "Test rapido",
        "Altro"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        headerCard
                        subjectSelectionCard
                        gradeInputCard
                        descriptionCard
                        dateSelectionCard
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Nuovo Voto")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveGrade()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .disabled(selectedSubject.isEmpty || description.isEmpty)
                }
            }
            .onAppear {
                if !dataManager.getAvailableSubjects().isEmpty {
                    selectedSubject = dataManager.getAvailableSubjects().first ?? ""
                }
            }
        }
        .alert("Attenzione", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var headerCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
            
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aggiungi Voto")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Inserisci un nuovo voto nel registro")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var subjectSelectionCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(selectedSubject.isEmpty ? .red.opacity(0.5) : Color(hex: dataManager.getColorFor(subject: selectedSubject)).opacity(0.5), lineWidth: 1.5)
                }
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "books.vertical")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Materia")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(dataManager.getAvailableSubjects(), id: \.self) { subject in
                        subjectButton(subject)
                    }
                }
            }
            .padding()
        }
    }
    
    private func subjectButton(_ subject: String) -> some View {
        Button(action: { selectedSubject = subject }) {
            HStack {
                Circle()
                    .fill(Color(hex: dataManager.getColorFor(subject: subject)))
                    .frame(width: 12, height: 12)
                
                Text(subject)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
            }
            .foregroundColor(selectedSubject == subject ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedSubject == subject ? .white : .white.opacity(0.1))
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedSubject)
    }
    
    private var gradeInputCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: getGradeColor(gradeValue)).opacity(0.5), lineWidth: 1.5)
                }
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "number.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Voto")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Preview del voto
                    VStack(spacing: 2) {
                        Text(String(format: gradeValue == floor(gradeValue) ? "%.0f" : "%.1f", gradeValue))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(getGradeJudgment(gradeValue))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: getGradeColor(gradeValue)))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                VStack(spacing: 10) {
                    Slider(value: Binding(
                        get: { gradeValue },
                        set: { newValue in
                            // Arrotonda al più vicino 0.5
                            gradeValue = round(newValue * 2) / 2
                        }
                    ), in: 1...10, step: 0.5)
                        .accentColor(Color(hex: getGradeColor(gradeValue)))
                    
                    HStack {
                        Text("1")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text("10")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding()
        }
    }
    
    private var descriptionCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(description.isEmpty ? .red.opacity(0.5) : .white.opacity(0.2), lineWidth: 1.5)
                }
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "text.alignleft")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Descrizione")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                    ForEach(gradeDescriptions, id: \.self) { desc in
                        descriptionButton(desc)
                    }
                }
                
                if description == "Altro" || (!gradeDescriptions.contains(description) && !description.isEmpty) {
                    TextField("Inserisci descrizione personalizzata", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.primary)
                }
            }
            .padding()
        }
    }
    
    private func descriptionButton(_ desc: String) -> some View {
        Button(action: { 
            if desc == "Altro" {
                description = ""
            } else {
                description = desc
            }
        }) {
            Text(desc)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(description == desc ? .black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(description == desc ? .white : .white.opacity(0.1))
                )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: description)
    }
    
    private var dateSelectionCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Data")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(selectedDate.formatted(.dateTime.day().month().year().locale(Locale(identifier: "it_IT"))))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                DatePicker("Seleziona data", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .accentColor(.purple)
                    .colorScheme(.dark)
            }
            .padding()
        }
    }
    
    private func saveGrade() {
        guard !selectedSubject.isEmpty else {
            alertMessage = "Seleziona una materia"
            showingAlert = true
            return
        }
        
        guard !description.isEmpty else {
            alertMessage = "Inserisci una descrizione per il voto"
            showingAlert = true
            return
        }
        
        let teacher = dataManager.getTeacherFor(subject: selectedSubject)
        let color = dataManager.getColorFor(subject: selectedSubject)
        
        let newGrade = Grade(
            subject: selectedSubject,
            value: gradeValue,
            date: selectedDate,
            description: description,
            teacher: teacher,
            color: color
        )
        
        dataManager.addGrade(newGrade)
        dismiss()
    }
    
    private func getGradeColor(_ value: Double) -> String {
        switch value {
        case 9...10:
            return "#4caf50"
        case 7..<9:
            return "#2196f3"
        case 6..<7:
            return "#ff9800"
        case 4..<6:
            return "#ff5722"
        default:
            return "#f44336"
        }
    }
    
    private func getGradeJudgment(_ value: Double) -> String {
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
            return "Grav. Insuff."
        }
    }
}

#Preview {
    AddGradeView()
        .environmentObject(DataManager())
}