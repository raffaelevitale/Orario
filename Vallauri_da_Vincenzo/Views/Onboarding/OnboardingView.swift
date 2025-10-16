//
//  OnboardingView.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject var dataManager: DataManager
    @State private var currentPage = 0
    @State private var showScheduleSetup = false
    @Environment(\.dismiss) var dismiss
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "calendar.badge.clock",
            title: "Benvenuto al Vallauri",
            description: "Gestisci il tuo orario scolastico, voti e compiti tutto in un'unica app",
            color: .blue
        ),
        OnboardingPage(
            icon: "clock.fill",
            title: "Orario Sempre con Te",
            description: "Visualizza le tue lezioni, ricevi notifiche prima dell'inizio e tieni traccia di tutto",
            color: .purple
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Analisi dei Voti",
            description: "Monitora i tuoi progressi con statistiche dettagliate e previsioni intelligenti",
            color: .green
        ),
        OnboardingPage(
            icon: "checklist",
            title: "Organizza i Compiti",
            description: "Pianifica compiti e verifiche con il planner settimanale integrato",
            color: .orange
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.3),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button("Salta") {
                        completeOnboarding()
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Bottom buttons
                VStack(spacing: 20) {
                    if currentPage == pages.count - 1 {
                        Button(action: {
                            showScheduleSetup = true
                        }) {
                            HStack {
                                Text("Inizia")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    } else {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                                Text("Avanti")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showScheduleSetup) {
            ScheduleSetupView(onComplete: {
                completeOnboarding()
            })
        }
        .onAppear {
            dataManager.loadInitialData()
        }
    }
    
    private func completeOnboarding() {
        HapticManager.shared.notification(type: .success)
        hasCompletedOnboarding = true
        dismiss()
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [page.color, page.color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 30)
            
            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Schedule Setup View

struct ScheduleSetupView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss
    let onComplete: () -> Void
    
    @State private var selectedClass: String = ""
    @State private var showingClassSelection = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.2), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Seleziona la Tua Classe")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Caricheremo automaticamente il tuo orario")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Class selection button
                    Button(action: {
                        HapticManager.shared.selection()
                        showingClassSelection = true
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: selectedClass.isEmpty ? "person.crop.circle.badge.questionmark" : "person.crop.circle.badge.checkmark")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedClass.isEmpty ? "Seleziona Classe" : selectedClass)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(selectedClass.isEmpty ? "Tocca per scegliere la tua classe" : "Tocca per cambiare")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(selectedClass.isEmpty ? Color.clear : Color.blue, lineWidth: 2)
                                )
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Continue button
                    Button(action: handleContinue) {
                        HStack {
                            Text("Continua")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedClass.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    .disabled(selectedClass.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salta") {
                        onComplete()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingClassSelection) {
            ClassSelectionView(selectedClass: $selectedClass)
                .environmentObject(dataManager)
                .environmentObject(settingsManager)
        }
    }
    
    private func handleContinue() {
        guard !selectedClass.isEmpty else { return }
        
        HapticManager.shared.impact(style: .medium)
        
        // Salva la classe selezionata e carica l'orario
        settingsManager.selectedClass = selectedClass
        dataManager.selectedClass = selectedClass
        dataManager.loadLessonsForClass(selectedClass)
        
        onComplete()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(DataManager())
}
