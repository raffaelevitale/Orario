//
//  ClassSelectionView.swift
//  Vallauri_da_Vincenzo
//

import SwiftUI

struct ClassSelectionView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var settingsManager: SettingsManager
    @Binding var selectedClass: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedYear = 0 // 0 = tutte, 1-5 = anni specifici
    @State private var isLoading = true
    
    private let scheduleLoader = ScheduleLoader.shared
    
    var filteredClasses: [String] {
        let allClasses = scheduleLoader.getAvailableClasses()
        
        var filtered = allClasses
        
        // Filtra per anno se selezionato
        if selectedYear > 0 {
            filtered = filtered.filter { $0.hasPrefix("\(selectedYear)") }
        }
        
        // Filtra per ricerca con linguaggio naturale
        if !searchText.isEmpty {
            filtered = filtered.filter { className in
                let query = searchText.lowercased()
                let classLower = className.lowercased()
                
                // Ricerca diretta
                if classLower.contains(query) {
                    return true
                }
                
                // Ricerca per anno in linguaggio naturale
                let yearMappings = [
                    "prima": "1", "primo": "1", "1°": "1",
                    "seconda": "2", "secondo": "2", "2°": "2",
                    "terza": "3", "terzo": "3", "3°": "3",
                    "quarta": "4", "quarto": "4", "4°": "4",
                    "quinta": "5", "quinto": "5", "5°": "5"
                ]
                
                for (word, digit) in yearMappings {
                    if query.contains(word) && classLower.hasPrefix(digit) {
                        return true
                    }
                }
                
                // Ricerca per specializzazione in linguaggio naturale
                let specializationMappings = [
                    "informatica": "inf", "info": "inf", "computer": "inf",
                    "elettronica": "elt", "elettrico": "elt", "elettricità": "elt",
                    "meccanica": "mec", "meccatronica": "mec",
                    "amministrazione": "afm", "finanza": "afm", "marketing": "afm", "aziendale": "afm",
                    "turismo": "tur", "turistico": "tur",
                    "liceo": "lic", "lssa": "lic", "scientifico": "lic"
                ]
                
                for (word, code) in specializationMappings {
                    if query.contains(word) && classLower.contains(code) {
                        return true
                    }
                }
                
                return false
            }
        }
        
        return filtered
    }
    
    // Raggruppa per anno
    var classesByYear: [Int: [String]] {
        var grouped: [Int: [String]] = [:]
        
        for className in filteredClasses {
            if let firstChar = className.first, let year = Int(String(firstChar)) {
                if grouped[year] == nil {
                    grouped[year] = []
                }
                grouped[year]?.append(className)
            }
        }
        
        return grouped
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background con tema personalizzato
                LinearGradient(
                    colors: settingsManager.backgroundColor.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    LoadingView(text: "Caricamento classi...")
                } else {
                    VStack(spacing: 20) {
                        // Header
                        headerView
                        
                        // Filtri anno
                        yearFilterView
                        
                        // Search bar
                        searchBar
                        
                        // Lista classi raggruppate
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(classesByYear.keys.sorted(), id: \.self) { year in
                                    if let classes = classesByYear[year] {
                                        yearSection(year: year, classes: classes)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Simula caricamento per mostrare l'animazione
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        isLoading = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("🎓 Seleziona la tua classe")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(scheduleLoader.getAvailableClasses().count) classi disponibili")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    // MARK: - Year Filter
    private var yearFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                yearFilterButton(title: "Tutte", year: 0)
                
                ForEach(1...5, id: \.self) { year in
                    yearFilterButton(title: "\(year)ª", year: year)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func yearFilterButton(title: String, year: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedYear = year
                HapticManager.shared.selection()
            }
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(selectedYear == year ? .bold : .regular)
                .foregroundColor(selectedYear == year ? .black : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(selectedYear == year ? Color.white : Color.white.opacity(0.2))
                        .shadow(
                            color: selectedYear == year ? .white.opacity(0.3) : .clear,
                            radius: 5,
                            x: 0,
                            y: 2
                        )
                )
        }
        .buttonStyle(BounceButtonStyle())
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))
            
            TextField("Cerca: '3A INF', 'terza informatica', 'quinta'...", text: $searchText)
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    HapticManager.shared.selection()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Year Section
    private func yearSection(year: Int, classes: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Anno \(year)")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.leading, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(classes.sorted(), id: \.self) { className in
                    classButton(className)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Class Button
    private func classButton(_ className: String) -> some View {
        Button(action: {
            selectClass(className)
        }) {
            VStack(spacing: 8) {
                // Icona classe
                Image(systemName: getIconForClass(className))
                    .font(.title2)
                    .foregroundColor(getColorForClass(className))
                
                // Nome classe
                Text(className)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Info lezioni
                if let info = scheduleLoader.getClassInfo(className) {
                    Text("\(info.totalLessons) ore")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(selectedClass == className ? 0.3 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(getColorForClass(className), lineWidth: selectedClass == className ? 2 : 0)
                    )
                    .shadow(
                        color: selectedClass == className ? getColorForClass(className).opacity(0.4) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
    
    // MARK: - Helper Functions
    private func selectClass(_ className: String) {
        HapticManager.shared.selection()
        
        selectedClass = className
        settingsManager.selectedClass = className
        settingsManager.saveSettings()
        
        // Carica le lezioni per questa classe
        dataManager.loadLessonsForClass(className)
        
        // Chiudi la schermata dopo un breve delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
    
    private func getIconForClass(_ className: String) -> String {
        if className.contains("INF") { return "desktopcomputer" }
        if className.contains("ELT") { return "bolt.fill" }
        if className.contains("MEC") { return "gearshape.2.fill" }
        if className.contains("AFM") { return "chart.line.uptrend.xyaxis" }
        if className.contains("TUR") { return "airplane" }
        if className.contains("LIC") { return "book.fill" }
        return "graduationcap.fill"
    }
    
    private func getColorForClass(_ className: String) -> Color {
        if className.contains("INF") { return Color(hex: "#7e57c2") }
        if className.contains("ELT") { return Color(hex: "#f44336") }
        if className.contains("MEC") { return Color(hex: "#795548") }
        if className.contains("AFM") { return Color(hex: "#4caf50") }
        if className.contains("TUR") { return Color(hex: "#ff9800") }
        if className.contains("LIC") { return Color(hex: "#2196f3") }
        return .blue
    }
}
