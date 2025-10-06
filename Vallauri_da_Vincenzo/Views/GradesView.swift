//
//  GradesView.swift
//  Vallauri_da_Vincenzo
//
//  Created by Raffaele Vitale on 25/09/25.
//

import SwiftUI

struct GradesView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedView: GradeViewMode = .bySubject
    @State private var showingAddGrade = false
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedSubject: String? = nil
    
    enum GradeViewMode: CaseIterable {
        case bySubject, summary
        
        var title: String {
            switch self {
            case .bySubject:
                return "Per Materia"
            case .summary:
                return "Riassunto"
            }
        }
        
        var icon: String {
            switch self {
            case .bySubject:
                return "books.vertical"
            case .summary:
                return "chart.bar"
            }
        }
    }
    
    private var collapseProgress: CGFloat {
        let t = min(max(scrollOffset / 120, 0), 1)
        return t
    }
    
    private var headerScale: CGFloat { 1.0 - 0.15 * collapseProgress }
    private var headerOpacity: Double { Double(1.0 - 0.3 * collapseProgress) }
    private var selectorScale: CGFloat { 1.0 - 0.2 * collapseProgress }
    private var selectorOpacity: Double { Double(1.0 - 0.2 * collapseProgress) }
    
    private struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background uniforme come nelle altre sezioni
                LinearGradient(
                    colors: settingsManager.backgroundColor.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header con titolo e pulsante
                    headerView
                        .scaleEffect(headerScale)
                        .opacity(headerOpacity)
                        .animation(.easeInOut(duration: 0.2), value: collapseProgress)
                    
                    viewSelector
                        .scaleEffect(selectorScale)
                        .opacity(selectorOpacity)
                        .animation(.easeInOut(duration: 0.2), value: collapseProgress)
                    
                    content
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("📊 Voti")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { showingAddGrade = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .sheet(isPresented: $showingAddGrade) {
            AddGradeView()
                .environmentObject(dataManager)
        }
    }
    
    private var viewSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(GradeViewMode.allCases, id: \.self) { mode in
                    viewModeButton(mode)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 15)
    }
    
    private func viewModeButton(_ mode: GradeViewMode) -> some View {
        Button(action: { selectedView = mode }) {
            HStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.caption)
                Text(mode.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(selectedView == mode ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedView == mode ? .white : .white.opacity(0.1))
            )
            .contentShape(Rectangle())
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedView)
    }
    
    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                // Elemento invisibile per il reset dello scroll
                Color.clear
                    .frame(height: 1)
                    .id("TOP")
                
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("GRADES_SCROLL")).minY)
                }
                .frame(height: 0)
                
                LazyVStack(spacing: 15) {
                    switch selectedView {
                    case .bySubject:
                        subjectView
                    case .summary:
                        summaryView
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .coordinateSpace(name: "GRADES_SCROLL")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .onChange(of: selectedView) { _ in
                withAnimation(.easeOut(duration: 0.5)) {
                    proxy.scrollTo("TOP", anchor: .top)
                    selectedSubject = nil // Reset materia selezionata
                }
            }
        }
    }
    
    // MARK: - Vista per Materie
    private var subjectView: some View {
        Group {
            if let selectedSubject = selectedSubject {
                // Vista dettagli materia selezionata
                subjectDetailView(for: selectedSubject)
            } else {
                // Vista elenco materie
                subjectListView
            }
        }
        .onChange(of: dataManager.grades) { _ in
            // Se abbiamo una materia selezionata, controlliamo se ha ancora voti
            if let currentSubject = selectedSubject {
                let hasGradesForSubject = dataManager.grades.contains { $0.subject == currentSubject }
                if !hasGradesForSubject {
                    // Non ci sono più voti per questa materia, torniamo alla home
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedSubject = nil
                    }
                }
            }
        }
    }
    
    // Vista elenco delle materie
    private var subjectListView: some View {
        Group {
            ForEach(dataManager.getGradesGroupedBySubject(), id: \.subject) { subjectGrades in
                SubjectSummaryCardView(subjectGrades: subjectGrades) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedSubject = subjectGrades.subject
                    }
                }
            }
            
            if dataManager.getGradesGroupedBySubject().isEmpty {
                emptyStateView
            }
        }
    }
    
    // Vista dettagli di una materia specifica
    private func subjectDetailView(for subject: String) -> some View {
        Group {
            if let subjectGrades = dataManager.getGradesGroupedBySubject().first(where: { $0.subject == subject }) {
                VStack(spacing: 15) {
                    // Header con pulsante back e info materia
                    subjectDetailHeader(for: subjectGrades)
                    
                    // Lista voti della materia
                    ForEach(subjectGrades.grades, id: \.id) { grade in
                        GradeCardView(grade: grade)
                    }
                }
            }
        }
    }
    
    // Header della vista dettagli materia
    private func subjectDetailHeader(for subjectGrades: SubjectGrades) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
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
            
            VStack(spacing: 12) {
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedSubject = nil
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(subjectGrades.subject)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
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
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prof. \(subjectGrades.teacher)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 8) {
                            Text("\(subjectGrades.gradeCount) vot\(subjectGrades.gradeCount == 1 ? "o" : "i")")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Circle()
                                .fill(.white.opacity(0.3))
                                .frame(width: 3, height: 3)
                            
                            Text("Ultimo: \(lastGradeForSubject(subjectGrades.subject))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding()
        }
    }
    
    private func lastGradeForSubject(_ subject: String) -> String {
        guard let lastGrade = dataManager.grades
                .filter({ $0.subject == subject })
                .sorted(by: { $0.date > $1.date })
                .first else {
            return "N/A"
        }
        return lastGrade.date.formatted(.dateTime.day().month().locale(Locale(identifier: "it_IT")))
    }
    

    
    // MARK: - Vista Riassunto
    private var summaryView: some View {
        VStack(spacing: 20) {
            // Card media generale
            overallSummaryCard
            
            // Statistiche per materia
            ForEach(dataManager.getGradesGroupedBySubject(), id: \.subject) { subjectGrades in
                SubjectAverageCardView(subjectGrades: subjectGrades)
            }
            
            if dataManager.getGradesGroupedBySubject().isEmpty {
                emptyStateView
            }
        }
    }
    
    private var overallSummaryCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThickMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
                .shadow(color: .purple.opacity(0.4), radius: 15, x: 0, y: 8)
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Media Generale")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Tutti i voti dell'anno scolastico")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Text(String(format: "%.1f", dataManager.overallAverage))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        )
                }
                
                HStack {
                    StatisticView(title: "Totale Voti", value: "\(dataManager.grades.count)", icon: "number.circle")
                    Spacer()
                    StatisticView(title: "Materie", value: "\(dataManager.getGradesGroupedBySubject().count)", icon: "books.vertical")
                    Spacer()
                    StatisticView(title: "Ultimo Voto", value: lastGradeDate, icon: "calendar")
                }
            }
            .padding()
        }
    }
    
    private var lastGradeDate: String {
        guard let lastGrade = dataManager.grades.sorted(by: { $0.date > $1.date }).first else {
            return "N/A"
        }
        return lastGrade.date.formatted(.dateTime.day().month().locale(Locale(identifier: "it_IT")))
    }
    
    private var emptyStateView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .frame(height: 200)
            
            VStack(spacing: 15) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Nessun voto inserito")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Tocca + per aggiungere il tuo primo voto")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button("Aggiungi Voto") {
                    showingAddGrade = true
                }
                .buttonStyle(.borderedProminent)
                .foregroundColor(.white)
            }
        }
        .padding(.top, 50)
    }
}

// Vista per le statistiche nel riassunto
struct StatisticView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// Vista riassuntiva per ogni materia (cliccabile)
struct SubjectSummaryCardView: View {
    let subjectGrades: SubjectGrades
    let onTap: () -> Void
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
                // Barra laterale colorata
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: subjectGrades.color))
                    .frame(width: 6)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(subjectGrades.subject)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Prof. \(subjectGrades.teacher)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Freccia per indicare che è cliccabile
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                            .scaleEffect(isPressed ? 1.2 : 1.0)
                    }
                    
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption)
                                .foregroundColor(Color(hex: subjectGrades.color))
                            
                            Text("Media: \(subjectGrades.formattedAverage)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "number.circle")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("\(subjectGrades.gradeCount) vot\(subjectGrades.gradeCount == 1 ? "o" : "i")")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.1))
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
            withAnimation(.spring(response: 0.15, dampingFraction: 0.9)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.9)) {
                    isPressed = false
                }
                onTap()
            }
        }
    }
}

#Preview {
    GradesView()
        .environmentObject(DataManager())
}
