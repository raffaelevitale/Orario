//
//  OnboardingView.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
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
    @Environment(\.dismiss) var dismiss
    let onComplete: () -> Void
    
    @State private var setupMethod: SetupMethod = .useDefault
    @State private var showImportSheet = false
    
    enum SetupMethod {
        case useDefault
        case manual
        case importFile
    }
    
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
                        
                        Text("Configura il tuo Orario")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Scegli come vuoi iniziare")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Setup options
                    VStack(spacing: 15) {
                        SetupOptionCard(
                            icon: "checkmark.circle.fill",
                            title: "Usa Orario Predefinito",
                            description: "Inizia con un orario di esempio già configurato",
                            isSelected: setupMethod == .useDefault,
                            action: { setupMethod = .useDefault }
                        )
                        
                        SetupOptionCard(
                            icon: "pencil.circle.fill",
                            title: "Inserimento Manuale",
                            description: "Aggiungi le tue lezioni una per una",
                            isSelected: setupMethod == .manual,
                            action: { setupMethod = .manual }
                        )
                        
                        SetupOptionCard(
                            icon: "doc.circle.fill",
                            title: "Importa da File",
                            description: "Carica un file CSV o JSON",
                            isSelected: setupMethod == .importFile,
                            action: { setupMethod = .importFile }
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
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
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
        .sheet(isPresented: $showImportSheet) {
            ImportScheduleView()
        }
    }
    
    private func handleContinue() {
        HapticManager.shared.impact(style: .medium)
        
        switch setupMethod {
        case .useDefault:
            // L'orario predefinito è già caricato
            onComplete()
        case .manual:
            // Naviga alla schermata di aggiunta manuale
            onComplete()
        case .importFile:
            showImportSheet = true
        }
    }
}

struct SetupOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.6))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Import Schedule View

struct ImportScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showDocumentPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "doc.badge.arrow.up")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Importa Orario")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Formati supportati: CSV, JSON")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Formato CSV richiesto:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("materia,docente,aula,giorno,inizio,fine,colore")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                    
                    Button("Seleziona File") {
                        showDocumentPicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(DataManager())
}
