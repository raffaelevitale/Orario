//
//  StatisticsView.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import SwiftUI
import Charts
import Foundation

struct StatisticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedTimeframe: Timeframe = .all
    @State private var selectedSubject: String?
    
    enum Timeframe: String, CaseIterable {
        case week = "Settimana"
        case month = "Mese"
        case trimester = "Trimestre"
        case all = "Tutto"
    }
    
    private var statistics: GradeStatistics {
        let grades = filteredGrades()
        return GradeStatistics(grades: grades)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Timeframe Selector
                timeframeSelector
                
                // Overview Cards
                overviewCards
                
                // Trend Chart
                trendChart
                
                // Subject Comparison
                subjectComparisonChart
                
                // Performance Distribution
                performanceDistribution
                
                // Monthly Performance
                monthlyPerformance
                
                // Insights
                insightsSection
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: settingsManager.backgroundColor.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Statistiche")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Timeframe Selector
    
    private var timeframeSelector: some View {
        Picker("Periodo", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    // MARK: - Overview Cards
    
    private var overviewCards: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                StatCard(
                    title: "Media Generale",
                    value: String(format: "%.2f", statistics.overallAverage),
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Mediana",
                    value: String(format: "%.2f", statistics.median),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
            }
            
            HStack(spacing: 15) {
                StatCard(
                    title: "Voto Più Alto",
                    value: statistics.highestGrade?.formattedValue ?? "-",
                    icon: "arrow.up.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Voto Più Basso",
                    value: statistics.lowestGrade?.formattedValue ?? "-",
                    icon: "arrow.down.circle.fill",
                    color: .red
                )
            }
        }
    }
    
    // MARK: - Trend Chart
    
    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Andamento Voti")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                let trend = statistics.trendAnalysis()
                Label(trend.description, systemImage: trend.icon)
                    .font(.subheadline)
                    .foregroundColor(trend.color)
            }
            
            if !statistics.grades.isEmpty {
                Chart {
                    ForEach(statistics.grades.sorted(by: { $0.date < $1.date })) { grade in
                        LineMark(
                            x: .value("Data", grade.date),
                            y: .value("Voto", grade.value)
                        )
                        .foregroundStyle(Color(hex: grade.color) ?? .blue)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Data", grade.date),
                            y: .value("Voto", grade.value)
                        )
                        .foregroundStyle(Color(hex: grade.color) ?? .blue)
                    }
                    
                    // Linea media
                    RuleMark(y: .value("Media", statistics.overallAverage))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                .frame(height: 250)
                .chartYScale(domain: 0...10)
            } else {
                Text("Nessun dato disponibile")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - Subject Comparison
    
    private var subjectComparisonChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Confronto per Materia")
                .font(.headline)
                .foregroundColor(.white)
            
            if !statistics.subjectAverages.isEmpty {
                Chart {
                    ForEach(Array(statistics.subjectAverages.sorted(by: { $0.value > $1.value })), id: \.key) { subject, average in
                        BarMark(
                            x: .value("Materia", subject),
                            y: .value("Media", average)
                        )
                        .foregroundStyle(Color(hex: dataManager.getColorFor(subject: subject)) ?? .blue)
                        .annotation(position: .top) {
                            Text(String(format: "%.1f", average))
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...10)
            } else {
                Text("Nessun dato disponibile")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - Performance Distribution
    
    private var performanceDistribution: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Distribuzione Voti")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                PerformanceBar(
                    label: "Eccellente",
                    count: statistics.excellentGrades.count,
                    total: statistics.grades.count,
                    color: .green
                )
                
                PerformanceBar(
                    label: "Buono",
                    count: statistics.goodGrades.count,
                    total: statistics.grades.count,
                    color: .blue
                )
                
                PerformanceBar(
                    label: "Sufficiente",
                    count: statistics.passingGrades.count,
                    total: statistics.grades.count,
                    color: .orange
                )
                
                PerformanceBar(
                    label: "Insufficiente",
                    count: statistics.failingGrades.count,
                    total: statistics.grades.count,
                    color: .red
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - Monthly Performance
    
    private var monthlyPerformance: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Performance Mensile")
                .font(.headline)
                .foregroundColor(.white)
            
            let monthly = statistics.monthlyAverages()
            
            if !monthly.isEmpty {
                Chart(monthly) { data in
                    BarMark(
                        x: .value("Mese", data.monthName),
                        y: .value("Media", data.average)
                    )
                    .foregroundStyle(.blue.gradient)
                    .annotation(position: .top) {
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f", data.average))
                                .font(.caption2)
                                .foregroundColor(.white)
                            Text("(\(data.count))")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...10)
            } else {
                Text("Nessun dato disponibile")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - Insights
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Analisi")
                .font(.headline)
                .foregroundColor(.white)
            
            if let best = statistics.bestSubject {
                InsightCard(
                    icon: "star.fill",
                    title: "Materia Migliore",
                    description: "\(best) con media \(String(format: "%.2f", statistics.subjectAverages[best] ?? 0))",
                    color: .green
                )
            }
            
            if let worst = statistics.worstSubject {
                InsightCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Da Migliorare",
                    description: "\(worst) con media \(String(format: "%.2f", statistics.subjectAverages[worst] ?? 0))",
                    color: .orange
                )
            }
            
            InsightCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Previsione Media Finale",
                description: String(format: "%.2f basato sul trend attuale", statistics.predictedFinalAverage()),
                color: .blue
            )
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - Helper Methods
    
    private func filteredGrades() -> [Grade] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeframe {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return dataManager.grades.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return dataManager.grades.filter { $0.date >= monthAgo }
        case .trimester:
            let trimesterAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return dataManager.grades.filter { $0.date >= trimesterAgo }
        case .all:
            return dataManager.grades
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PerformanceBar: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(count) (\(Int(percentage * 100))%)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}
