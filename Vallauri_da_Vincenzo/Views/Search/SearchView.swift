//
//  SearchView.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import SwiftUI
import Combine

struct SearchView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var plannerManager = WeeklyPlannerManager()
    @StateObject private var searchViewModel = SearchViewModel()
    
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @FocusState private var isSearchFocused: Bool
    
    enum SearchFilter: String, CaseIterable {
        case all = "Tutto"
        case lessons = "Lezioni"
        case grades = "Voti"
        case tasks = "Compiti"
        
        var icon: String {
            switch self {
            case .all: return "magnifyingglass"
            case .lessons: return "calendar"
            case .grades: return "chart.bar"
            case .tasks: return "checklist"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: settingsManager.backgroundColor.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                    
                    // Filter Pills
                    filterPills
                    
                    // Results
                    if searchText.isEmpty {
                        emptyState
                    } else {
                        searchResults
                    }
                }
            }
            .navigationTitle("Cerca")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            searchViewModel.configure(
                dataManager: dataManager,
                plannerManager: plannerManager
            )
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Cerca lezioni, voti, compiti...", text: $searchText)
                    .foregroundColor(.white)
                    .focused($isSearchFocused)
                    .onChange(of: searchText) { newValue in
                        searchViewModel.search(query: newValue, filter: selectedFilter)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        HapticManager.shared.impact(style: .light)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
    }
    
    // MARK: - Filter Pills
    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SearchFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        action: {
                            selectedFilter = filter
                            searchViewModel.search(query: searchText, filter: filter)
                            HapticManager.shared.selection()
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Cerca tra le tue lezioni, voti e compiti")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Search Results
    
    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                if searchViewModel.isSearching {
                    ProgressView()
                        .tint(.white)
                        .padding()
                } else if searchViewModel.searchResults.isEmpty {
                    noResultsView
                } else {
                    // Lessons
                    if !searchViewModel.searchResults.lessons.isEmpty && (selectedFilter == .all || selectedFilter == .lessons) {
                        SearchSection(title: "Lezioni", icon: "calendar") {
                            ForEach(searchViewModel.searchResults.lessons) { lesson in
                                LessonSearchResultCard(lesson: lesson, searchText: searchText)
                            }
                        }
                    }
                    
                    // Grades
                    if !searchViewModel.searchResults.grades.isEmpty && (selectedFilter == .all || selectedFilter == .grades) {
                        SearchSection(title: "Voti", icon: "chart.bar") {
                            ForEach(searchViewModel.searchResults.grades) { grade in
                                GradeSearchResultCard(grade: grade, searchText: searchText)
                            }
                        }
                    }
                    
                    // Tasks
                    if !searchViewModel.searchResults.tasks.isEmpty && (selectedFilter == .all || selectedFilter == .tasks) {
                        SearchSection(title: "Compiti", icon: "checklist") {
                            ForEach(searchViewModel.searchResults.tasks) { task in
                                TaskSearchResultCard(task: task, searchText: searchText)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 15) {
            Image(systemName: "exclamationmark.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.4))
            
            Text("Nessun risultato")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Prova con parole chiave diverse")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let filter: SearchView.SearchFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.white.opacity(0.1))
            .foregroundColor(.white)
            .cornerRadius(20)
        }
    }
}

// MARK: - Search Section

struct SearchSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(.white)
            
            VStack(spacing: 10) {
                content()
            }
        }
    }
}

// MARK: - Result Cards

struct LessonSearchResultCard: View {
    let lesson: Lesson
    let searchText: String
    
    var body: some View {
        HStack(spacing: 15) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.fromHex(lesson.color) ?? .blue)
                .frame(width: 4, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.subject)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(lesson.teacher)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Text(lesson.dayName)
                    Text("•")
                    Text("\(lesson.startTime) - \(lesson.endTime)")
                    Text("•")
                    Text(lesson.classroom)
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .onTapGesture {
            HapticManager.shared.impact(style: .light)
        }
    }
}

struct GradeSearchResultCard: View {
    let grade: Grade
    let searchText: String
    
    var body: some View {
        HStack(spacing: 15) {
            // Grade value
            ZStack {
                Circle()
                    .fill(Color.fromHex(grade.gradeColor) ?? .blue)
                    .frame(width: 50, height: 50)
                
                Text(grade.formattedValue)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(grade.subject)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(grade.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(grade.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .onTapGesture {
            HapticManager.shared.impact(style: .light)
        }
    }
}

struct TaskSearchResultCard: View {
    let task: PlannerTask
    let searchText: String
    
    var body: some View {
        HStack(spacing: 15) {
            // Task icon
            ZStack {
                Circle()
                    .fill(task.type.color.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Image(systemName: task.type.icon)
                    .font(.title3)
                    .foregroundColor(task.type.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Text(task.subject)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Label(task.priority.rawValue, systemImage: task.priority.icon)
                        .font(.caption)
                        .foregroundColor(task.priority.color)
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text(task.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .onTapGesture {
            HapticManager.shared.impact(style: .light)
        }
    }
}

// MARK: - Search ViewModel

class SearchViewModel: ObservableObject {
    @Published var searchResults = SearchResults()
    @Published var isSearching = false
    
    private var dataManager: DataManager?
    private var plannerManager: WeeklyPlannerManager?
    private var searchTask: Task<Void, Never>?
    
    func configure(dataManager: DataManager, plannerManager: WeeklyPlannerManager) {
        self.dataManager = dataManager
        self.plannerManager = plannerManager
    }
    
    func search(query: String, filter: SearchView.SearchFilter) {
        // Cancella la ricerca precedente
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = SearchResults()
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            // Simula un piccolo delay per evitare troppe ricerche
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 secondi
            
            guard !Task.isCancelled else { return }
            
            await performSearch(query: query, filter: filter)
            
            await MainActor.run {
                isSearching = false
            }
        }
    }
    
    private func performSearch(query: String, filter: SearchView.SearchFilter) async {
        let lowercasedQuery = query.lowercased()
        var results = SearchResults()
        
        // Search lessons
        if filter == .all || filter == .lessons {
            results.lessons = dataManager?.lessons.filter { lesson in
                lesson.subject.lowercased().contains(lowercasedQuery) ||
                lesson.teacher.lowercased().contains(lowercasedQuery) ||
                lesson.classroom.lowercased().contains(lowercasedQuery)
            } ?? []
        }
        
        // Search grades
        if filter == .all || filter == .grades {
            results.grades = dataManager?.grades.filter { grade in
                grade.subject.lowercased().contains(lowercasedQuery) ||
                grade.description.lowercased().contains(lowercasedQuery) ||
                grade.teacher.lowercased().contains(lowercasedQuery)
            } ?? []
        }
        
        // Search tasks
        if filter == .all || filter == .tasks {
            results.tasks = plannerManager?.getAllTasks().filter { task in
                task.title.lowercased().contains(lowercasedQuery) ||
                task.description.lowercased().contains(lowercasedQuery) ||
                task.subject.lowercased().contains(lowercasedQuery)
            } ?? []
        }
        
        await MainActor.run {
            self.searchResults = results
        }
    }
}

struct SearchResults {
    var lessons: [Lesson] = []
    var grades: [Grade] = []
    var tasks: [PlannerTask] = []
    
    var isEmpty: Bool {
        lessons.isEmpty && grades.isEmpty && tasks.isEmpty
    }
}
