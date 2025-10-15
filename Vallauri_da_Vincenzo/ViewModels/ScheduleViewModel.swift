//
//  ScheduleViewModel.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import SwiftUI
import Combine

class ScheduleViewModel: ObservableObject {
    @Published var lessons: [Lesson] = []
    @Published var selectedDay: Int = 1 // Lunedì di default
    @Published var currentWeekLessons: [Int: [Lesson]] = [:]
    @Published var showOnlyCurrentDay: Bool = false
    
    private let dataManager: DataManager
    private let cacheManager: CacheManager
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: DataManager, cacheManager: CacheManager) {
        self.dataManager = dataManager
        self.cacheManager = cacheManager
        
        setupBindings()
        updateSelectedDay()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        dataManager.$lessons
            .sink { [weak self] lessons in
                self?.lessons = lessons
                self?.updateWeekLessons()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func updateSelectedDay() {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        // Converti da domenica=1 a lunedì=1
        if weekday == 1 { // Domenica
            selectedDay = 1 // Mostra lunedì
        } else if weekday == 7 { // Sabato
            selectedDay = 1 // Mostra lunedì
        } else {
            selectedDay = weekday - 1
        }
    }
    
    func getLessonsForDay(_ day: Int) -> [Lesson] {
        // Prova prima dalla cache
        if let cached = cacheManager.getCachedLessons(forDay: day) {
            return cached
        }
        
        // Altrimenti filtra e salva in cache
        let dayLessons = lessons.filter { $0.dayOfWeek == day }
            .sorted { $0.startTime < $1.startTime }
        
        cacheManager.cacheLessons(dayLessons, forDay: day)
        return dayLessons
    }
    
    func getCurrentLesson() -> Lesson? {
        dataManager.getCurrentLesson()
    }
    
    func getNextLesson() -> Lesson? {
        dataManager.getNextLesson()
    }
    
    // MARK: - Computed Properties
    
    var todayLessons: [Lesson] {
        getLessonsForDay(selectedDay)
    }
    
    var weekDays: [String] {
        ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì"]
    }
    
    // MARK: - Private Methods
    
    private func updateWeekLessons() {
        currentWeekLessons = [:]
        for day in 1...5 {
            currentWeekLessons[day] = getLessonsForDay(day)
        }
    }
}
