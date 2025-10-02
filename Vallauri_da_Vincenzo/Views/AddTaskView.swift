//
//  AddTaskView.swift
//  Vallauri_da_Vincenzo
//

import SwiftUI

struct AddTaskView: View {
    @ObservedObject var plannerManager: WeeklyPlannerManager
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedSubject = ""
    @State private var selectedType = TaskType.homework
    @State private var selectedPriority = TaskPriority.medium
    @State private var dueDate = Date()
    @State private var tags: [String] = []
    @State private var newTag = ""
    
    private var availableSubjects: [String] {
        dataManager.getAvailableSubjects()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [.black, .gray.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Titolo")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Inserisci il titolo del compito", text: $title)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Description section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Descrizione")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Descrizione opzionale", text: $description, axis: .vertical)
                                .textFieldStyle(CustomTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        // Subject selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Materia")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Picker("Materia", selection: $selectedSubject) {
                                ForEach(availableSubjects, id: \.self) { subject in
                                    Text(subject).tag(subject)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Type and Priority
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tipo")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Picker("Tipo", selection: $selectedType) {
                                    ForEach(TaskType.allCases, id: \.self) { type in
                                        Label(type.rawValue, systemImage: type.icon)
                                            .tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Priorità")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Picker("Priorità", selection: $selectedPriority) {
                                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                                        Label(priority.rawValue, systemImage: priority.icon)
                                            .foregroundColor(priority.color)
                                            .tag(priority)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        // Due date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Data di scadenza")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            DatePicker(
                                "Data di scadenza",
                                selection: $dueDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .tint(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Tags section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tag")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Add new tag
                            HStack {
                                TextField("Aggiungi tag", text: $newTag)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                Button(action: addTag) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            
                            // Display tags
                            if !tags.isEmpty {
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 80))
                                ], spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        TagView(tag: tag) {
                                            removeTag(tag)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Nuovo Compito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Annulla")
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveTask) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                            Text("Salva")
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || selectedSubject.isEmpty)
                    .opacity((title.trimmingCharacters(in: .whitespaces).isEmpty || selectedSubject.isEmpty) ? 0.5 : 1.0)
                }
            }
            .onAppear {
                if !availableSubjects.isEmpty {
                    selectedSubject = availableSubjects[0]
                }
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespaces)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func saveTask() {
        let task = PlannerTask(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            subject: selectedSubject,
            type: selectedType,
            priority: selectedPriority,
            dueDate: dueDate,
            estimatedDuration: 60,
            tags: tags
        )
        
        plannerManager.addTask(task)
        dismiss()
    }
}

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.3), lineWidth: 1)
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(.ultraThinMaterial)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            }
    }
}

#Preview {
    AddTaskView(plannerManager: WeeklyPlannerManager(), dataManager: DataManager())
}