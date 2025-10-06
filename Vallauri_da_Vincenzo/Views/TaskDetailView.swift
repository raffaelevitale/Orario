//
//  TaskDetailView.swift
//  Vallauri_da_Vincenzo
//

import SwiftUI

struct TaskDetailView: View {
    @State var task: PlannerTask
    @ObservedObject var plannerManager: WeeklyPlannerManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
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
                    VStack(alignment: .leading, spacing: 24) {
                        // Header card
                        VStack(alignment: .leading, spacing: 16) {
                            // Title and completion status
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(task.title)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .strikethrough(task.isCompleted)
                                    
                                    Text(task.subject)
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Button(action: toggleCompletion) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.title)
                                        .foregroundColor(task.isCompleted ? .green : .white.opacity(0.6))
                                }
                            }
                            
                            // Type and Status indicators
                            HStack(spacing: 12) {
                                // Type
                                Label(task.type.rawValue, systemImage: task.type.icon)
                                    .font(.caption)
                                    .foregroundColor(task.type.color)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(task.type.color.opacity(0.2))
                                    .clipShape(Capsule())
                                
                                // Status
                                if task.isOverdue {
                                    Label("In ritardo", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.red.opacity(0.2))
                                        .clipShape(Capsule())
                                } else if task.isCompleted {
                                    Label("Completato", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.green.opacity(0.2))
                                        .clipShape(Capsule())
                                } else if Calendar.current.isToday(task.dueDate) {
                                    Label("Oggi", systemImage: "clock.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.blue.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(task.priority.color.opacity(0.3), lineWidth: 1)
                        }
                        
                        // Description
                        if !task.description.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Descrizione")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(task.description)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Dettagli")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                // Due date
                                DetailRow(
                                    icon: "calendar",
                                    title: "Scadenza",
                                    value: formatDate(task.dueDate),
                                    color: task.isOverdue ? .red : .blue
                                )
                                
                                // Estimated duration
                                DetailRow(
                                    icon: "clock",
                                    title: "Tempo stimato",
                                    value: "\\(task.estimatedDuration / 60)h \\(task.estimatedDuration % 60)m",
                                    color: .orange
                                )
                                
                                // Created date
                                DetailRow(
                                    icon: "plus.circle",
                                    title: "Creato",
                                    value: formatDate(task.createdDate),
                                    color: .gray
                                )
                                
                                // Completed date
                                if let completedDate = task.completedDate {
                                    DetailRow(
                                        icon: "checkmark.circle",
                                        title: "Completato",
                                        value: formatDate(completedDate),
                                        color: .green
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Tags
                        if !task.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tag")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 80))
                                ], spacing: 8) {
                                    ForEach(task.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .fontWeight(.medium)
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
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Actions
                        VStack(spacing: 12) {
                            // Complete/Uncomplete button
                            Button(action: toggleCompletion) {
                                HStack {
                                    Image(systemName: task.isCompleted ? "arrow.counterclockwise" : "checkmark")
                                        .font(.headline)
                                    Text(task.isCompleted ? "Segna come non completato" : "Segna come completato")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(task.isCompleted ? .orange : .green)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            // Edit button
                            Button(action: { isEditing = true }) {
                                HStack {
                                    Image(systemName: "pencil")
                                        .font(.headline)
                                    Text("Modifica")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            // Delete button
                            Button(action: { showingDeleteAlert = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.headline)
                                    Text("Elimina")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("Dettagli Compito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Elimina Compito", isPresented: $showingDeleteAlert) {
                Button("Elimina", role: .destructive) {
                    plannerManager.deleteTask(task)
                    dismiss()
                }
                Button("Annulla", role: .cancel) { }
            } message: {
                Text("Sei sicuro di voler eliminare questo compito? Questa azione non può essere annullata.")
            }
            .sheet(isPresented: $isEditing) {
                EditTaskView(task: $task, plannerManager: plannerManager)
            }
        }
    }
    
    private func toggleCompletion() {
        plannerManager.toggleTaskCompletion(task)
        // Update local state
        task.isCompleted.toggle()
        task.completedDate = task.isCompleted ? Date() : nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

struct EditTaskView: View {
    @Binding var task: PlannerTask
    @ObservedObject var plannerManager: WeeklyPlannerManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedType: TaskType = .homework
    @State private var dueDate: Date = Date()
    @State private var estimatedDuration: Int = 60
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [.black, .gray.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Titolo")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Titolo", text: $title)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Descrizione")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Descrizione", text: $description, axis: .vertical)
                                .textFieldStyle(CustomTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        // Type selection (full width)
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
                            Text("Data di scadenza")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            DatePicker(
                                "Data di scadenza",
                                selection: $dueDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.compact)
                            .tint(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tempo stimato: \\(estimatedDuration) minuti")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Slider(value: Binding(
                                get: { Double(estimatedDuration) },
                                set: { estimatedDuration = Int($0) }
                            ), in: 15...240, step: 15)
                            .tint(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Modifica Compito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveChanges()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadTaskData()
            }
        }
    }
    
    private func loadTaskData() {
        title = task.title
        description = task.description
        selectedType = task.type
        dueDate = task.dueDate
        estimatedDuration = task.estimatedDuration
    }
    
    private func saveChanges() {
        task.title = title.trimmingCharacters(in: .whitespaces)
        task.description = description.trimmingCharacters(in: .whitespaces)
        task.type = selectedType
        task.dueDate = dueDate
        task.estimatedDuration = estimatedDuration
        
        plannerManager.updateTask(task)
        dismiss()
    }
}

#Preview {
    TaskDetailView(
        task: PlannerTask(
            title: "Esempio di compito",
            description: "Questa è una descrizione di esempio per il compito",
            subject: "Matematica",
            type: .homework,
            dueDate: Date(),
            estimatedDuration: 90,
            tags: ["algebra", "equazioni"]
        ),
        plannerManager: WeeklyPlannerManager()
    )
}