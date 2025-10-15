//
//  ColorExtensions.swift
//  Vallauri_da_Vincenzo
//
//  Created on 15/10/2025
//

import SwiftUI
import UIKit

extension Color {
    /// Inizializza un Color da una stringa esadecimale
    /// - Parameter hexString: Stringa in formato "#RRGGBB" o "RRGGBB"
    static func fromHex(_ hexString: String) -> Color? {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        guard Scanner(string: hex).scanHexInt64(&int) else {
            return nil
        }
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Converte il Color in stringa esadecimale
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else {
            return nil
        }
        
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    // Colori personalizzati per l'app
    static let appPrimary = Color.fromHex("#007AFF") ?? .blue
    static let appSecondary = Color.fromHex("#5856D6") ?? .purple
    static let appSuccess = Color.fromHex("#34C759") ?? .green
    static let appWarning = Color.fromHex("#FF9500") ?? .orange
    static let appError = Color.fromHex("#FF3B30") ?? .red
    
    // Colori per le materie (default)
    static let subjectBlue = Color.fromHex("#42a5f5") ?? .blue
    static let subjectGreen = Color.fromHex("#66bb6a") ?? .green
    static let subjectPurple = Color.fromHex("#7e57c2") ?? .purple
    static let subjectOrange = Color.fromHex("#ffa726") ?? .orange
    static let subjectRed = Color.fromHex("#ef5350") ?? .red
    static let subjectTeal = Color.fromHex("#26a69a") ?? .teal
    static let subjectBrown = Color.fromHex("#8d6e63") ?? .brown
    static let subjectYellow = Color.fromHex("#fbc02d") ?? .yellow
}

// MARK: - Gradient Extensions

extension LinearGradient {
    /// Crea un gradient dal tema corrente
    static func themed(_ colors: [Color]) -> LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Gradient glass effect
    static let glassEffect = LinearGradient(
        colors: [
            Color.white.opacity(0.25),
            Color.white.opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Shadow Extensions

extension View {
    /// Applica un'ombra glass effect
    func glassShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .shadow(color: .white.opacity(0.1), radius: 1, x: 0, y: -1)
    }
    
    /// Applica un'ombra card
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    /// Applica un'ombra profonda
    func deepShadow() -> some View {
        self.shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Card Styles

struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 15
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .glassShadow()
    }
}

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 12
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.1))
            )
            .cardShadow()
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 15) -> some View {
        self.modifier(GlassCardStyle(cornerRadius: cornerRadius))
    }
    
    func card(cornerRadius: CGFloat = 12) -> some View {
        self.modifier(CardStyle(cornerRadius: cornerRadius))
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .blue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = .gray
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(color)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.2))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    func primaryButton(color: Color = .blue) -> some View {
        self.buttonStyle(PrimaryButtonStyle(color: color))
    }
    
    func secondaryButton(color: Color = .gray) -> some View {
        self.buttonStyle(SecondaryButtonStyle(color: color))
    }
}

// MARK: - Loading State

struct LoadingView: View {
    var text: String = "Caricamento..."
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text(text)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Toast Notification

struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case success, error, warning, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            
            Text(message)
                .foregroundColor(.white)
                .font(.subheadline)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.color, lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .shadow(radius: 10)
    }
}
