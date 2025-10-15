//
//  BackgroundRefreshManager.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import Foundation
import UIKit
import BackgroundTasks
import WidgetKit

class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    
    private let refreshIdentifier = "com.vallauri.schedule.refresh"
    private let dataManager: DataManager
    
    private init() {
        // Inizializza con un'istanza temporanea, verrà configurato dopo
        self.dataManager = DataManager()
    }
    
    // MARK: - Setup
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshIdentifier,
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        print("✅ Background tasks registrati")
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshIdentifier)
        
        // Programma per tra 1 ora
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ App refresh programmato")
        } catch {
            print("❌ Errore programmazione app refresh: \(error)")
        }
    }
    
    // MARK: - Handle Background Task
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        print("🔄 Background refresh in esecuzione...")
        
        // Programma il prossimo refresh
        scheduleAppRefresh()
        
        // Crea un'operazione per il refresh
        let refreshOperation = BlockOperation {
            self.performRefresh()
        }
        
        // Gestisci la scadenza del task
        task.expirationHandler = {
            refreshOperation.cancel()
            print("⚠️ Background task scaduto")
        }
        
        // Completa il task quando l'operazione finisce
        refreshOperation.completionBlock = {
            task.setTaskCompleted(success: !refreshOperation.isCancelled)
            print("✅ Background refresh completato")
        }
        
        // Esegui l'operazione
        OperationQueue().addOperation(refreshOperation)
    }
    
    // MARK: - Refresh Operations
    
    private func performRefresh() {
        // 1. Aggiorna le Live Activities se necessario
        updateLiveActivities()
        
        // 2. Pulisci le cache scadute
        CacheManager.shared.clearExpiredCaches()
        
        // 3. Prefetch dati per domani
        prefetchTomorrowData()
        
        // 4. Aggiorna i widget
        WidgetCenter.shared.reloadAllTimelines()
        
        // 5. Programma notifiche se necessario
        scheduleUpcomingNotifications()
    }
    
    private func updateLiveActivities() {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            dataManager.checkAndManageLiveActivities()
        }
        #endif
    }
    
    private func prefetchTomorrowData() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowWeekday = calendar.component(.weekday, from: tomorrow)
        
        // Converti da domenica=1 a lunedì=1
        let dayOfWeek = tomorrowWeekday == 1 ? 7 : tomorrowWeekday - 1
        
        if dayOfWeek >= 1 && dayOfWeek <= 5 {
            // È un giorno di scuola, prefetch delle lezioni
            let tomorrowLessons = dataManager.lessons
                .filter { $0.dayOfWeek == dayOfWeek }
                .sorted { $0.startTime < $1.startTime }
            
            CacheManager.shared.cacheLessons(tomorrowLessons, forDay: dayOfWeek)
            print("✅ Prefetch lezioni di domani completato")
        }
    }
    
    private func scheduleUpcomingNotifications() {
        guard SettingsManager.shared.enableNotifications else { return }
        
        // Verifica se ci sono notifiche da programmare per domani
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowWeekday = calendar.component(.weekday, from: tomorrow)
        let dayOfWeek = tomorrowWeekday == 1 ? 7 : tomorrowWeekday - 1
        
        if dayOfWeek >= 1 && dayOfWeek <= 5 {
            let tomorrowLessons = dataManager.lessons.filter { $0.dayOfWeek == dayOfWeek }
            NotificationManager.shared.scheduleNotifications(for: tomorrowLessons)
            print("✅ Notifiche per domani programmate")
        }
    }
    
    // MARK: - Manual Refresh
    
    func refreshNow(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.performRefresh()
            
            DispatchQueue.main.async {
                completion(true)
                HapticManager.shared.notification(type: .success)
            }
        }
    }
    
    // MARK: - Utility
    
    func cancelAllBackgroundTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshIdentifier)
        print("🚫 Background tasks cancellati")
    }
}

// MARK: - App Lifecycle Integration

extension BackgroundRefreshManager {
    func handleAppDidEnterBackground() {
        scheduleAppRefresh()
        
        // Salva lo stato corrente
        dataManager.saveData()
        
        print("📱 App in background - refresh programmato")
    }
    
    func handleAppWillEnterForeground() {
        // Aggiorna i dati quando l'app torna in foreground
        refreshNow { success in
            if success {
                print("✅ Dati aggiornati al ritorno in foreground")
            }
        }
    }
}
