//
//  CacheManager.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import Foundation
import UIKit

class CacheManager {
    static let shared = CacheManager()
    
    // MARK: - Cache Storage
    
    private var lessonsCache: [Int: CachedLessons] = [:]
    private var gradesCache: [String: CachedGrades] = [:]
    private var statisticsCache: CachedStatistics?
    
    private let cacheQueue = DispatchQueue(label: "com.vallauri.cache", qos: .utility)
    private let cacheExpirationTime: TimeInterval = 3600 // 1 ora
    
    // MARK: - Cached Data Structures
    
    private struct CachedLessons {
        let lessons: [Lesson]
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 3600
        }
    }
    
    private struct CachedGrades {
        let grades: [Grade]
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 3600
        }
    }
    
    private struct CachedStatistics {
        let statistics: GradeStatistics
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 1800 // 30 minuti
        }
    }
    
    private init() {
        setupMemoryWarningObserver()
    }
    
    // MARK: - Lessons Cache
    
    func cacheLessons(_ lessons: [Lesson], forDay day: Int) {
        cacheQueue.async { [weak self] in
            self?.lessonsCache[day] = CachedLessons(
                lessons: lessons,
                timestamp: Date()
            )
        }
    }
    
    func getCachedLessons(forDay day: Int) -> [Lesson]? {
        guard let cached = lessonsCache[day], !cached.isExpired else {
            return nil
        }
        return cached.lessons
    }
    
    // MARK: - Grades Cache
    
    func cacheGrades(_ grades: [Grade], forSubject subject: String) {
        cacheQueue.async { [weak self] in
            self?.gradesCache[subject] = CachedGrades(
                grades: grades,
                timestamp: Date()
            )
        }
    }
    
    func getCachedGrades(forSubject subject: String) -> [Grade]? {
        guard let cached = gradesCache[subject], !cached.isExpired else {
            return nil
        }
        return cached.grades
    }
    
    // MARK: - Statistics Cache
    
    func cacheStatistics(_ statistics: GradeStatistics) {
        cacheQueue.async { [weak self] in
            self?.statisticsCache = CachedStatistics(
                statistics: statistics,
                timestamp: Date()
            )
        }
    }
    
    func getCachedStatistics() -> GradeStatistics? {
        guard let cached = statisticsCache, !cached.isExpired else {
            return nil
        }
        return cached.statistics
    }
    
    // MARK: - Cache Management
    
    func clearAllCaches() {
        cacheQueue.async { [weak self] in
            self?.lessonsCache.removeAll()
            self?.gradesCache.removeAll()
            self?.statisticsCache = nil
            print("🗑️ Cache completamente svuotata")
        }
    }
    
    func clearLessonsCache() {
        cacheQueue.async { [weak self] in
            self?.lessonsCache.removeAll()
            print("🗑️ Cache lezioni svuotata")
        }
    }
    
    func clearGradesCache() {
        cacheQueue.async { [weak self] in
            self?.gradesCache.removeAll()
            self?.statisticsCache = nil
            print("🗑️ Cache voti svuotata")
        }
    }
    
    func clearExpiredCaches() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Rimuovi lessons cache scadute
            let expiredLessonDays = self.lessonsCache.filter { $0.value.isExpired }.map { $0.key }
            expiredLessonDays.forEach { self.lessonsCache.removeValue(forKey: $0) }
            
            // Rimuovi grades cache scadute
            let expiredSubjects = self.gradesCache.filter { $0.value.isExpired }.map { $0.key }
            expiredSubjects.forEach { self.gradesCache.removeValue(forKey: $0) }
            
            // Rimuovi statistics cache se scaduta
            if let stats = self.statisticsCache, stats.isExpired {
                self.statisticsCache = nil
            }
            
            let totalRemoved = expiredLessonDays.count + expiredSubjects.count
            if totalRemoved > 0 {
                print("🗑️ Rimosse \(totalRemoved) cache scadute")
            }
        }
    }
    
    // MARK: - Cache Info
    
    func getCacheInfo() -> CacheInfo {
        CacheInfo(
            lessonsCacheCount: lessonsCache.count,
            gradesCacheCount: gradesCache.count,
            hasStatisticsCache: statisticsCache != nil
        )
    }
    
    struct CacheInfo {
        let lessonsCacheCount: Int
        let gradesCacheCount: Int
        let hasStatisticsCache: Bool
        
        var totalCacheSize: Int {
            lessonsCacheCount + gradesCacheCount + (hasStatisticsCache ? 1 : 0)
        }
    }
    
    // MARK: - Memory Management
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        print("⚠️ Memoria bassa - Svuoto le cache")
        clearAllCaches()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Prefetching Manager

class PrefetchingManager {
    static let shared = PrefetchingManager()
    
    private let cacheManager = CacheManager.shared
    private var prefetchQueue: OperationQueue
    
    private init() {
        prefetchQueue = OperationQueue()
        prefetchQueue.maxConcurrentOperationCount = 2
        prefetchQueue.qualityOfService = .utility
    }
    
    // MARK: - Prefetch Methods
    
    func prefetchWeekLessons(from dataManager: DataManager) {
        prefetchQueue.addOperation { [weak self] in
            guard let self = self else { return }
            
            for day in 1...5 { // Lunedì-Venerdì
                let lessons = dataManager.lessons
                    .filter { $0.dayOfWeek == day }
                    .sorted { $0.startTime < $1.startTime }
                
                self.cacheManager.cacheLessons(lessons, forDay: day)
            }
            
            print("✅ Prefetch lezioni settimanali completato")
        }
    }
    
    func prefetchGradesBySubject(from dataManager: DataManager) {
        prefetchQueue.addOperation { [weak self] in
            guard let self = self else { return }
            
            let subjects = Set(dataManager.grades.map { $0.subject })
            
            for subject in subjects {
                let subjectGrades = dataManager.grades
                    .filter { $0.subject == subject }
                    .sorted { $0.date > $1.date }
                
                self.cacheManager.cacheGrades(subjectGrades, forSubject: subject)
            }
            
            print("✅ Prefetch voti per materia completato")
        }
    }
    
    func prefetchStatistics(from dataManager: DataManager) {
        prefetchQueue.addOperation { [weak self] in
            guard let self = self else { return }
            
            let statistics = GradeStatistics(grades: dataManager.grades)
            self.cacheManager.cacheStatistics(statistics)
            
            print("✅ Prefetch statistiche completato")
        }
    }
    
    func prefetchAll(from dataManager: DataManager) {
        prefetchWeekLessons(from: dataManager)
        prefetchGradesBySubject(from: dataManager)
        prefetchStatistics(from: dataManager)
    }
    
    func cancelAllPrefetching() {
        prefetchQueue.cancelAllOperations()
        print("🚫 Prefetching cancellato")
    }
}
