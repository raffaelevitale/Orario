//
//  TimerSettingsView.swift
//  Vallauri_da_Vincenzo
//

import SwiftUI

struct TimerSettingsView: View {
    @ObservedObject var timerManager: StudyTimerManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var pomodoroSession: Double = 25
    @State private var shortBreak: Double = 5
    @State private var longBreak: Double = 15
    @State private var longBreakInterval: Double = 4
    @State private var customDuration: Double = 30
    @State private var isNotificationEnabled: Bool = true
    @State private var isSoundEnabled: Bool = true
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [.black, .gray.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Pomodoro Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Impostazioni Pomodoro")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 16) {
                                SettingSlider(
                                    title: "Durata sessione",
                                    value: $pomodoroSession,
                                    range: 15...60,
                                    step: 5,
                                    unit: "min",
                                    color: .red
                                )
                                
                                SettingSlider(
                                    title: "Pausa breve",
                                    value: $shortBreak,
                                    range: 3...15,
                                    step: 1,
                                    unit: "min",
                                    color: .blue
                                )
                                
                                SettingSlider(
                                    title: "Pausa lunga",
                                    value: $longBreak,
                                    range: 10...30,
                                    step: 5,
                                    unit: "min",
                                    color: .purple
                                )
                                
                                SettingSlider(
                                    title: "Intervallo pausa lunga",
                                    value: $longBreakInterval,
                                    range: 2...8,
                                    step: 1,
                                    unit: "pomodori",
                                    color: .orange
                                )
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Custom Timer Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Timer Personalizzato")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            SettingSlider(
                                title: "Durata predefinita",
                                value: $customDuration,
                                range: 10...120,
                                step: 5,
                                unit: "min",
                                color: .green
                            )
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Notification Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notifiche e Suoni")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 16) {
                                SettingToggle(
                                    title: "Notifiche",
                                    subtitle: "Ricevi notifiche al completamento delle sessioni",
                                    isOn: $isNotificationEnabled,
                                    color: .blue
                                )
                                
                                SettingToggle(
                                    title: "Suoni",
                                    subtitle: "Riproduci suono al completamento",
                                    isOn: $isSoundEnabled,
                                    color: .green
                                )
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Reset Button
                        Button(action: resetToDefaults) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.headline)
                                Text("Ripristina impostazioni predefinite")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.red.opacity(0.5), lineWidth: 1)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveSettings()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
        }
    }
    
    private func loadCurrentSettings() {
        pomodoroSession = Double(timerManager.pomodoroSession / 60)
        shortBreak = Double(timerManager.shortBreak / 60)
        longBreak = Double(timerManager.longBreak / 60)
        longBreakInterval = Double(timerManager.longBreakInterval)
        customDuration = Double(timerManager.customDuration / 60)
        isNotificationEnabled = timerManager.isNotificationEnabled
        isSoundEnabled = timerManager.isSoundEnabled
    }
    
    private func saveSettings() {
        timerManager.updateSettings(
            pomodoroSession: Int(pomodoroSession * 60),
            shortBreak: Int(shortBreak * 60),
            longBreak: Int(longBreak * 60),
            longBreakInterval: Int(longBreakInterval),
            customDuration: Int(customDuration * 60),
            isNotificationEnabled: isNotificationEnabled,
            isSoundEnabled: isSoundEnabled
        )
        dismiss()
    }
    
    private func resetToDefaults() {
        pomodoroSession = 25
        shortBreak = 5
        longBreak = 15
        longBreakInterval = 4
        customDuration = 30
        isNotificationEnabled = true
        isSoundEnabled = true
    }
}

struct SettingSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\\(Int(value)) \\(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Slider(value: $value, in: range, step: step) {
                Text(title)
            } minimumValueLabel: {
                Text("\\(Int(range.lowerBound))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            } maximumValueLabel: {
                Text("\\(Int(range.upperBound))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .tint(color)
        }
    }
}

struct SettingToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(color)
        }
    }
}

#Preview {
    TimerSettingsView(timerManager: StudyTimerManager())
}