//
//  ThemeManager.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import SwiftUI
import Combine

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .default
    @Published var isDynamicTheme: Bool = false
    @Published var customWallpaper: UIImage?
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadTheme()
    }
    
    func saveTheme() {
        if let encoded = try? JSONEncoder().encode(currentTheme) {
            userDefaults.set(encoded, forKey: "currentTheme")
        }
        userDefaults.set(isDynamicTheme, forKey: "isDynamicTheme")
        
        if let wallpaper = customWallpaper,
           let data = wallpaper.jpegData(compressionQuality: 0.8) {
            userDefaults.set(data, forKey: "customWallpaper")
        }
    }
    
    private func loadTheme() {
        if let data = userDefaults.data(forKey: "currentTheme"),
           let theme = try? JSONDecoder().decode(AppTheme.self, from: data) {
            currentTheme = theme
        }
        
        isDynamicTheme = userDefaults.bool(forKey: "isDynamicTheme")
        
        if let data = userDefaults.data(forKey: "customWallpaper"),
           let image = UIImage(data: data) {
            customWallpaper = image
        }
    }
    
    func applyTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
        saveTheme()
        HapticManager.shared.selection()
    }
    
    func toggleDynamicTheme() {
        isDynamicTheme.toggle()
        saveTheme()
        HapticManager.shared.impact(style: .medium)
    }
    
    func getCurrentTheme() -> AppTheme {
        if isDynamicTheme {
            return getDynamicTheme()
        }
        return currentTheme
    }
    
    private func getDynamicTheme() -> AppTheme {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<9:
            return .sunrise
        case 9..<17:
            return .daytime
        case 17..<20:
            return .sunset
        default:
            return .nighttime
        }
    }
}

// MARK: - App Theme

struct AppTheme: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let primaryColors: [String]
    let accentColor: String
    let cardBackgroundOpacity: Double
    let textPrimaryColor: String
    let textSecondaryColor: String
    
    var colors: [Color] {
        primaryColors.compactMap { Color.fromHex($0) }
    }
    
    var accent: Color {
        Color.fromHex(accentColor) ?? .blue
    }
    
    var cardBackground: Color {
        Color.white.opacity(cardBackgroundOpacity)
    }
    
    var textPrimary: Color {
        Color.fromHex(textPrimaryColor) ?? .white
    }
    
    var textSecondary: Color {
        Color.fromHex(textSecondaryColor) ?? .white.opacity(0.7)
    }
    
    // MARK: - Preset Themes
    
    static let `default` = AppTheme(
        id: "default",
        name: "Predefinito",
        primaryColors: ["#000000", "#1a1a1a"],
        accentColor: "#007AFF",
        cardBackgroundOpacity: 0.1,
        textPrimaryColor: "#FFFFFF",
        textSecondaryColor: "#B3B3B3"
    )
    
    static let ocean = AppTheme(
        id: "ocean",
        name: "Oceano",
        primaryColors: ["#001f3f", "#003d7a", "#0066cc"],
        accentColor: "#00d4ff",
        cardBackgroundOpacity: 0.15,
        textPrimaryColor: "#FFFFFF",
        textSecondaryColor: "#99e6ff"
    )
    
    static let forest = AppTheme(
        id: "forest",
        name: "Foresta",
        primaryColors: ["#0a3622", "#1a5c3f", "#2d8659"],
        accentColor: "#4ade80",
        cardBackgroundOpacity: 0.15,
        textPrimaryColor: "#FFFFFF",
        textSecondaryColor: "#a7f3d0"
    )
    
    static let sunset = AppTheme(
        id: "sunset",
        name: "Tramonto",
        primaryColors: ["#4a1942", "#742c5e", "#a04575"],
        accentColor: "#ff6b9d",
        cardBackgroundOpacity: 0.15,
        textPrimaryColor: "#FFFFFF",
        textSecondaryColor: "#ffc6dc"
    )
    
    static let lavender = AppTheme(
        id: "lavender",
        name: "Lavanda",
        primaryColors: ["#2d1b4e", "#4a2c6d", "#6b3f8f"],
        accentColor: "#a78bfa",
        cardBackgroundOpacity: 0.15,
        textPrimaryColor: "#FFFFFF",
        textSecondaryColor: "#ddd6fe"
    )
    
    static let fire = AppTheme(
        id: "fire",
        name: "Fuoco",
        primaryColors: ["#4a1410", "#7a2318", "#a83a2a"],
        accentColor: "#fb923c",
        cardBackgroundOpacity: 0.15,
        textPrimaryColor: "#FFFFFF",
        textSecondaryColor: "#fed7aa"
    )
    
    static let midnight = AppTheme(
        id: "midnight",
        name: "Mezzanotte",
        primaryColors: ["#0f0f23", "#1a1a3e", "#2d2d5f"],
        accentColor: "#818cf8",
        cardBackgroundOpacity: 0.12,
        textPrimaryColor: "#FFFFFF",
        textSecondaryColor: "#c7d2fe"
    )
    
    static let mint = AppTheme(
        id: "mint",
        name: "Menta",
        primaryColors: ["#0a3d3d", "#146666", "#1e8e8e"],
        accentColor: "#5eead4",
        cardBackgroundOpacity: 0.15,
        textPrimaryColor: "#FFFFFF",
        textSecondaryColor: "#ccfbf1"
    )
    
    // Dynamic themes
    static let sunrise = AppTheme(
        id: "sunrise",
        name: "Alba",
        primaryColors: ["#1e293b", "#fbbf24", "#fb923c"],
        accentColor: "#fcd34d",
        cardBackgroundOpacity: 0.15,
        textPrimaryColor: "#FFFFFF",
        textSecondaryColor: "#fef3c7"
    )
    
    static let daytime = AppTheme(
        id: "daytime",
        name: "Giorno",
        primaryColors: ["#0ea5e9", "#38bdf8", "#7dd3fc"],
        accentColor: "#0284c7",
        cardBackgroundOpacity: 0.2,
        textPrimaryColor: "#FFFFFF",
        textSecondaryColor: "#e0f2fe"
    )
    
    static let nighttime = AppTheme(
        id: "nighttime",
        name: "Notte",
        primaryColors: ["#0f172a", "#1e293b", "#334155"],
        accentColor: "#60a5fa",
        cardBackgroundOpacity: 0.12,
        textPrimaryColor: "#FFFFFF",
        textSecondaryColor: "#cbd5e1"
    )
    
    static let allThemes: [AppTheme] = [
        .default, .ocean, .forest, .sunset, .lavender,
        .fire, .midnight, .mint
    ]
}

// MARK: - Theme Selector View

struct ThemeSelectorView: View {
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.dismiss) var dismiss
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: themeManager.getCurrentTheme().colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Dynamic Theme Toggle
                        dynamicThemeToggle
                        
                        // Theme Grid
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(AppTheme.allThemes) { theme in
                                ThemePreviewCard(
                                    theme: theme,
                                    isSelected: themeManager.currentTheme.id == theme.id && !themeManager.isDynamicTheme,
                                    action: {
                                        themeManager.isDynamicTheme = false
                                        themeManager.applyTheme(theme)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Custom Wallpaper Section
                        customWallpaperSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Temi")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fine") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.getCurrentTheme().accent)
                }
            }
        }
        .environmentObject(themeManager)
    }
    
    private var dynamicThemeToggle: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Tema Dinamico", systemImage: "sun.and.horizon.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Cambia automaticamente durante il giorno")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Toggle("", isOn: $themeManager.isDynamicTheme)
                    .labelsHidden()
                    .onChange(of: themeManager.isDynamicTheme) { _ in
                        themeManager.toggleDynamicTheme()
                    }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            
            if themeManager.isDynamicTheme {
                HStack(spacing: 10) {
                    ForEach([
                        ("Alba", "sunrise.fill", AppTheme.sunrise),
                        ("Giorno", "sun.max.fill", AppTheme.daytime),
                        ("Tramonto", "sunset.fill", AppTheme.sunset),
                        ("Notte", "moon.stars.fill", AppTheme.nighttime)
                    ], id: \.0) { name, icon, theme in
                        VStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.title3)
                            Text(name)
                                .font(.caption2)
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: theme.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var customWallpaperSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Personalizzazione Avanzata")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            Button(action: {
                // Implementa image picker
                HapticManager.shared.impact(style: .medium)
            }) {
                HStack {
                    Image(systemName: "photo.fill")
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sfondo Personalizzato")
                            .font(.headline)
                        Text("Usa la tua immagine come sfondo")
                            .font(.caption)
                            .opacity(0.7)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .opacity(0.5)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
            }
            .padding(.horizontal)
        }
    }
}

struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Preview colors
                ZStack {
                    LinearGradient(
                        colors: theme.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5)
                    }
                }
                .frame(height: 120)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 3)
                )
                
                // Theme name
                Text(theme.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

