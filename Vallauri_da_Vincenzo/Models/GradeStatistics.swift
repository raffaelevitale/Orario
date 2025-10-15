//
//  GradeStatistics.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import SwiftUI
import Charts

// MARK: - Statistics Models

struct GradeStatistics {
    let grades: [Grade]
    
    // MARK: - Overall Statistics
    
    var overallAverage: Double {
        guard !grades.isEmpty else { return 0.0 }
        return grades.reduce(0) { $0 + $1.value } / Double(grades.count)
    }
    
    var median: Double {
        guard !grades.isEmpty else { return 0.0 }
        let sorted = grades.map { $0.value }.sorted()
        let count = sorted.count
        
        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
        } else {
            return sorted[count / 2]
        }
    }
    
    var mode: Double? {
        let values = grades.map { $0.value }
        let counts = Dictionary(grouping: values) { $0 }.mapValues { $0.count }
        let maxCount = counts.values.max() ?? 0
        
        guard maxCount > 1 else { return nil }
        return counts.filter { $0.value == maxCount }.keys.first
    }
    
    var standardDeviation: Double {
        guard !grades.isEmpty else { return 0.0 }
        let mean = overallAverage
        let variance = grades.reduce(0.0) { $0 + pow($1.value - mean, 2) } / Double(grades.count)
        return sqrt(variance)
    }
    
    var highestGrade: Grade? {
        grades.max { $0.value < $1.value }
    }
    
    var lowestGrade: Grade? {
        grades.min { $0.value < $1.value }
    }
    
    // MARK: - Performance Categories
    
    var excellentGrades: [Grade] {
        grades.filter { $0.value >= 9.0 }
    }
    
    var goodGrades: [Grade] {
        grades.filter { $0.value >= 7.0 && $0.value < 9.0 }
    }
    
    var passingGrades: [Grade] {
        grades.filter { $0.value >= 6.0 && $0.value < 7.0 }
    }
    
    var failingGrades: [Grade] {
        grades.filter { $0.value < 6.0 }
    }
    
    var performanceDistribution: [String: Int] {
        [
            "Eccellente (9-10)": excellentGrades.count,
            "Buono (7-8.9)": goodGrades.count,
            "Sufficiente (6-6.9)": passingGrades.count,
            "Insufficiente (<6)": failingGrades.count
        ]
    }
    
    // MARK: - Subject Statistics
    
    func statisticsForSubject(_ subject: String) -> SubjectStatistics {
        let subjectGrades = grades.filter { $0.subject == subject }
        return SubjectStatistics(subject: subject, grades: subjectGrades)
    }
    
    var subjectAverages: [String: Double] {
        let subjects = Set(grades.map { $0.subject })
        var averages: [String: Double] = [:]
        
        for subject in subjects {
            let subjectGrades = grades.filter { $0.subject == subject }
            let average = subjectGrades.reduce(0.0) { $0 + $1.value } / Double(subjectGrades.count)
            averages[subject] = average
        }
        
        return averages
    }
    
    var bestSubject: String? {
        subjectAverages.max { $0.value < $1.value }?.key
    }
    
    var worstSubject: String? {
        subjectAverages.min { $0.value < $1.value }?.key
    }
    
    // MARK: - Trend Analysis
    
    func trendAnalysis() -> GradeTrend {
        guard grades.count >= 5 else { return .stable }
        
        let sortedGrades = grades.sorted { $0.date < $1.date }
        let recentCount = min(5, sortedGrades.count)
        let recentGrades = Array(sortedGrades.suffix(recentCount))
        let olderGrades = Array(sortedGrades.prefix(recentCount))
        
        let recentAverage = recentGrades.reduce(0.0) { $0 + $1.value } / Double(recentGrades.count)
        let olderAverage = olderGrades.reduce(0.0) { $0 + $1.value } / Double(olderGrades.count)
        
        let difference = recentAverage - olderAverage
        
        if difference > 0.5 {
            return .improving
        } else if difference < -0.5 {
            return .declining
        } else {
            return .stable
        }
    }
    
    func predictedFinalAverage() -> Double {
        guard !grades.isEmpty else { return 0.0 }
        
        let trend = trendAnalysis()
        let currentAverage = overallAverage
        
        switch trend {
        case .improving:
            return min(10.0, currentAverage + 0.3)
        case .declining:
            return max(0.0, currentAverage - 0.3)
        case .stable:
            return currentAverage
        }
    }
    
    // MARK: - Monthly Performance
    
    func monthlyAverages() -> [MonthlyPerformance] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: grades) { grade in
            calendar.component(.month, from: grade.date)
        }
        
        return grouped.map { month, grades in
            let average = grades.reduce(0.0) { $0 + $1.value } / Double(grades.count)
            return MonthlyPerformance(month: month, average: average, count: grades.count)
        }.sorted { $0.month < $1.month }
    }
    
    // MARK: - Comparison with Goals
    
    func performanceVsGoal(goal: Double) -> GoalComparison {
        let difference = overallAverage - goal
        let percentage = (overallAverage / goal) * 100
        
        return GoalComparison(
            currentAverage: overallAverage,
            goal: goal,
            difference: difference,
            percentage: percentage,
            isAchieved: overallAverage >= goal
        )
    }
}

// MARK: - Subject Statistics

struct SubjectStatistics {
    let subject: String
    let grades: [Grade]
    
    var average: Double {
        guard !grades.isEmpty else { return 0.0 }
        return grades.reduce(0.0) { $0 + $1.value } / Double(grades.count)
    }
    
    var gradeCount: Int {
        grades.count
    }
    
    var trend: GradeTrend {
        guard grades.count >= 3 else { return .stable }
        
        let sorted = grades.sorted { $0.date < $1.date }
        let recent = Array(sorted.suffix(2))
        let older = Array(sorted.prefix(2))
        
        let recentAvg = recent.reduce(0.0) { $0 + $1.value } / Double(recent.count)
        let olderAvg = older.reduce(0.0) { $0 + $1.value } / Double(older.count)
        
        if recentAvg > olderAvg + 0.3 {
            return .improving
        } else if recentAvg < olderAvg - 0.3 {
            return .declining
        } else {
            return .stable
        }
    }
    
    var lastGrade: Grade? {
        grades.max { $0.date < $1.date }
    }
}

// MARK: - Supporting Types

enum GradeTrend {
    case improving
    case declining
    case stable
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .orange
        }
    }
    
    var description: String {
        switch self {
        case .improving: return "In miglioramento"
        case .declining: return "In calo"
        case .stable: return "Stabile"
        }
    }
}

struct MonthlyPerformance: Identifiable {
    let id = UUID()
    let month: Int
    let average: Double
    let count: Int
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.monthSymbols[month - 1].capitalized
    }
}

struct GoalComparison {
    let currentAverage: Double
    let goal: Double
    let difference: Double
    let percentage: Double
    let isAchieved: Bool
    
    var status: String {
        if isAchieved {
            return "Obiettivo raggiunto!"
        } else {
            return "Mancano \(String(format: "%.2f", abs(difference))) punti"
        }
    }
}

// MARK: - Chart Data Types

struct GradeChartData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let subject: String
}

struct SubjectAverageData: Identifiable {
    let id = UUID()
    let subject: String
    let average: Double
    let color: String
}
