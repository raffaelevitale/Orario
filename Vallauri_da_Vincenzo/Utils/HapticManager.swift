//
//  HapticManager.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import SwiftUI
import UIKit
import CoreHaptics

class HapticManager {
    static let shared = HapticManager()
    
    private var hapticEngine: CHHapticEngine?
    private let impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator]
    private let notificationGenerator: UINotificationFeedbackGenerator
    private let selectionGenerator: UISelectionFeedbackGenerator
    
    private init() {
        // Inizializza i generatori di feedback
        impactGenerators = [
            .light: UIImpactFeedbackGenerator(style: .light),
            .medium: UIImpactFeedbackGenerator(style: .medium),
            .heavy: UIImpactFeedbackGenerator(style: .heavy),
            .soft: UIImpactFeedbackGenerator(style: .soft),
            .rigid: UIImpactFeedbackGenerator(style: .rigid)
        ]
        
        notificationGenerator = UINotificationFeedbackGenerator()
        selectionGenerator = UISelectionFeedbackGenerator()
        
        // Prepara i generatori
        impactGenerators.values.forEach { $0.prepare() }
        notificationGenerator.prepare()
        selectionGenerator.prepare()
        
        // Inizializza Haptic Engine per feedback avanzati
        setupHapticEngine()
    }
    
    // MARK: - Setup
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("⚠️ Haptic Engine non supportato su questo dispositivo")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            // Riavvia l'engine se si ferma
            hapticEngine?.stoppedHandler = { [weak self] reason in
                print("⚠️ Haptic Engine fermato: \(reason)")
                try? self?.hapticEngine?.start()
            }
            
            // Gestisci il reset
            hapticEngine?.resetHandler = { [weak self] in
                print("🔄 Haptic Engine resettato")
                try? self?.hapticEngine?.start()
            }
        } catch {
            print("❌ Errore inizializzazione Haptic Engine: \(error)")
        }
    }
    
    // MARK: - Basic Haptics
    
    /// Feedback tattile leggero
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        impactGenerators[style]?.impactOccurred()
    }
    
    /// Feedback per selezione (es. picker, segmented control)
    func selection() {
        selectionGenerator.selectionChanged()
    }
    
    /// Feedback per notifiche (success, warning, error)
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }
    
    // MARK: - Advanced Haptics
    
    /// Feedback per il completamento di un'azione importante
    func success() {
        playPattern(intensity: 1.0, sharpness: 0.5, duration: 0.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playPattern(intensity: 0.8, sharpness: 0.3, duration: 0.1)
        }
    }
    
    /// Feedback per un errore o azione non permessa
    func error() {
        playPattern(intensity: 1.0, sharpness: 1.0, duration: 0.1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playPattern(intensity: 0.8, sharpness: 0.9, duration: 0.1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.playPattern(intensity: 0.6, sharpness: 0.8, duration: 0.1)
        }
    }
    
    /// Feedback per un'azione che richiede attenzione
    func warning() {
        playPattern(intensity: 0.8, sharpness: 0.7, duration: 0.3)
    }
    
    /// Feedback progressivo (es. durante uno swipe)
    func progress(amount: CGFloat) {
        let intensity = min(1.0, max(0.3, amount))
        playPattern(intensity: Float(intensity), sharpness: 0.5, duration: 0.05)
    }
    
    /// Feedback per l'inizio di una lezione
    func lessonStart() {
        playCustomPattern([
            (intensity: 0.6, sharpness: 0.4, delay: 0.0),
            (intensity: 0.8, sharpness: 0.5, delay: 0.1),
            (intensity: 1.0, sharpness: 0.6, delay: 0.2)
        ])
    }
    
    /// Feedback per la fine di una lezione
    func lessonEnd() {
        playCustomPattern([
            (intensity: 1.0, sharpness: 0.6, delay: 0.0),
            (intensity: 0.7, sharpness: 0.4, delay: 0.1)
        ])
    }
    
    /// Feedback per aggiunta voto
    func gradeAdded(value: Double) {
        if value >= 9.0 {
            // Voto eccellente - feedback positivo forte
            success()
        } else if value >= 6.0 {
            // Voto sufficiente - feedback neutro
            impact(style: .medium)
        } else {
            // Voto insufficiente - feedback di attenzione
            warning()
        }
    }
    
    /// Feedback per completamento task
    func taskCompleted() {
        playCustomPattern([
            (intensity: 0.7, sharpness: 0.5, delay: 0.0),
            (intensity: 0.9, sharpness: 0.6, delay: 0.05)
        ])
    }
    
    // MARK: - Private Methods
    
    private func playPattern(intensity: Float, sharpness: Float, duration: TimeInterval) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            // Fallback a feedback semplice
            impact(style: .medium)
            return
        }
        
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0,
            duration: duration
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("❌ Errore riproduzione haptic pattern: \(error)")
        }
    }
    
    private func playCustomPattern(_ events: [(intensity: Float, sharpness: Float, delay: TimeInterval)]) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            impact(style: .medium)
            return
        }
        
        let hapticEvents = events.map { event in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: event.intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: event.sharpness)
                ],
                relativeTime: event.delay
            )
        }
        
        do {
            let pattern = try CHHapticPattern(events: hapticEvents, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("❌ Errore riproduzione custom pattern: \(error)")
        }
    }
}

// MARK: - SwiftUI Integration

extension View {
    /// Aggiunge haptic feedback a un tap gesture
    func hapticTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            HapticManager.shared.impact(style: style)
        }
    }
    
    /// Aggiunge haptic feedback quando il valore cambia
    func hapticOnChange<V: Equatable>(of value: V, style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onChange(of: value) { _ in
            HapticManager.shared.impact(style: style)
        }
    }
}
