//
//  GradesViewModel.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import SwiftUI
import Combine

class GradesViewModel: ObservableObject {
    @Published var grades: [Grade] = []
    @Published var groupedGrades: [SubjectGrades] = []
    @Published var selectedSubject: String?
    @Published var sortOrder: GradeSortOrder = .dateDescending
    @Published var filterType: GradeFilterType = .all
    @Published var searchText: String = ""
    
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    enum GradeSortOrder {
        case dateAscending, dateDescending
        case valueAscending, valueDescending
        case subjectAscending
    }
    
    enum GradeFilterType {
        case all
        case passing // >= 6
        case failing // < 6
        case excellent // >= 9
    }
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        dataManager.$grades
            .sink { [weak self] grades in
                self?.grades = grades
                self?.updateGroupedGrades()
            }
            .store(in: &cancellables)
        
        // Aggiorna quando cambiano filtri o ordinamento
        Publishers.CombineLatest3($sortOrder, $filterType, $searchText)
            .sink { [weak self] _, _, _ in
                self?.updateGroupedGrades()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func addGrade(_ grade: Grade) {
        dataManager.addGrade(grade)
        HapticManager.shared.notification(type: .success)
    }
    
    func deleteGrade(_ grade: Grade) {
        dataManager.deleteGrade(grade)
        HapticManager.shared.notification(type: .warning)
    }
    
    func updateGrade(_ grade: Grade) {
        dataManager.updateGrade(grade)
        HapticManager.shared.notification(type: .success)
    }
    
    // MARK: - Computed Properties
    
    var overallAverage: Double {
        let filteredGrades = getFilteredGrades()
        guard !filteredGrades.isEmpty else { return 0.0 }
        return filteredGrades.reduce(0) { $0 + $1.value } / Double(filteredGrades.count)
    }
    
    var formattedOverallAverage: String {
        if overallAverage == floor(overallAverage) {
            return String(format: "%.0f", overallAverage)
        } else {
            return String(format: "%.2f", overallAverage)
        }
    }
    
    var passingGradesCount: Int {
        grades.filter { $0.value >= 6.0 }.count
    }
    
    var failingGradesCount: Int {
        grades.filter { $0.value < 6.0 }.count
    }
    
    var excellentGradesCount: Int {
        grades.filter { $0.value >= 9.0 }.count
    }
    
    // MARK: - Private Methods
    
    private func updateGroupedGrades() {
        let filteredGrades = getFilteredGrades()
        let subjects = Set(filteredGrades.map { $0.subject })
        
        groupedGrades = subjects.compactMap { subject in
            let subjectGrades = filteredGrades.filter { $0.subject == subject }
            guard !subjectGrades.isEmpty else { return nil }
            
            let sortedGrades = sortGrades(subjectGrades)
            
            return SubjectGrades(
                subject: subject,
                color: dataManager.getColorFor(subject: subject),
                teacher: dataManager.getTeacherFor(subject: subject),
                grades: sortedGrades
            )
        }.sorted { $0.subject < $1.subject }
    }
    
    private func getFilteredGrades() -> [Grade] {
        var filtered = grades
        
        // Applica filtro per tipo
        switch filterType {
        case .all:
            break
        case .passing:
            filtered = filtered.filter { $0.value >= 6.0 }
        case .failing:
            filtered = filtered.filter { $0.value < 6.0 }
        case .excellent:
            filtered = filtered.filter { $0.value >= 9.0 }
        }
        
        // Applica ricerca testuale
        if !searchText.isEmpty {
            filtered = filtered.filter { grade in
                grade.subject.localizedCaseInsensitiveContains(searchText) ||
                grade.description.localizedCaseInsensitiveContains(searchText) ||
                grade.teacher.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    private func sortGrades(_ grades: [Grade]) -> [Grade] {
        switch sortOrder {
        case .dateAscending:
            return grades.sorted { $0.date < $1.date }
        case .dateDescending:
            return grades.sorted { $0.date > $1.date }
        case .valueAscending:
            return grades.sorted { $0.value < $1.value }
        case .valueDescending:
            return grades.sorted { $0.value > $1.value }
        case .subjectAscending:
            return grades.sorted { $0.subject < $1.subject }
        }
    }
}
