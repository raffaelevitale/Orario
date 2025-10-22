//
//  HomeViewModel.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var currentLesson: Lesson?
    @Published var nextLesson: Lesson?
    @Published var isSchoolTime: Bool = false
    @Published var todayTasks: [PlannerTask] = []
    @Published var currentTime = Date()
    @Published var isGreetingVisible = true
    
    private let dataManager: DataManager
    private let plannerManager: WeeklyPlannerManager
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    init(dataManager: DataManager, plannerManager: WeeklyPlannerManager) {
        self.dataManager = dataManager
        self.plannerManager = plannerManager
        
        setupBindings()
        startTimer()
        updateCurrentState()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Osserva i cambiamenti nelle lezioni
        dataManager.$lessons
            .sink { [weak self] _ in
                self?.updateCurrentState()
            }
            .store(in: &cancellables)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
            self?.updateCurrentState()
        }
    }
    
    // MARK: - Public Methods
    
    func updateCurrentState() {
        isSchoolTime = calculateIsSchoolTime()
        currentLesson = dataManager.getCurrentLesson()
        nextLesson = dataManager.getNextLesson()
        todayTasks = plannerManager.getTasksForDay(currentTime)
    }
    
    func hideGreeting() {
        withAnimation(.easeInOut(duration: 1)) {
            isGreetingVisible = false
        }
    }
    
    // MARK: - Computed Properties
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12:
            return "Buongiorno"
        case 12..<17:
            return "Buon pomeriggio"
        case 17..<22:
            return "Buonasera"
        default:
            return "Buonanotte"
        }
    }
    
    var formattedDate: String {
        return DateFormatter.italianDateFormatter.string(from: currentTime).capitalized
    }
    
    var nextSchoolDay: Date? {
        let calendar = Calendar.current
        var nextDay = calendar.date(byAdding: .day, value: 1, to: currentTime) ?? currentTime
        var attempts = 0
        let maxAttempts = 14 // Max 2 settimane di ricerca

        // Trova il prossimo giorno di scuola (Lunedì-Venerdì)
        while attempts < maxAttempts {
            let weekday = calendar.component(.weekday, from: nextDay)
            if weekday >= 2 && weekday <= 6 {
                return nextDay
            }
            // Usa guard per gestire il caso di fallimento della date operation
            guard let next = calendar.date(byAdding: .day, value: 1, to: nextDay) else {
                return nil
            }
            nextDay = next
            attempts += 1
        }

        // Se dopo 14 giorni non troviamo un giorno di scuola, ritorna nil
        return nil
    }
    
    // MARK: - Private Methods
    
    private func calculateIsSchoolTime() -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentTime)
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let currentMinutes = hour * 60 + minute
        
        // Lunedì-Venerdì (2-6), dalle 7:50 alle 14:00
        return weekday >= 2 && weekday <= 6 && currentMinutes >= 470 && currentMinutes <= 840
    }
}
