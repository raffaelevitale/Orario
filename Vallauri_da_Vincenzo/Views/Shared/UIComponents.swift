//
//  UIComponents.swift
//  Vallauri_da_Vincenzo
//
//  Componenti UI riutilizzabili per consistenza UX
//

import SwiftUI

// MARK: - Modern Card Style
struct ModernCardStyle: ViewModifier {
    let backgroundColor: Color
    let shadowColor: Color
    
    init(backgroundColor: Color = Color.white.opacity(0.1), shadowColor: Color = .black.opacity(0.3)) {
        self.backgroundColor = backgroundColor
        self.shadowColor = shadowColor
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(backgroundColor)
                    .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
            )
    }
}

extension View {
    func modernCard(backgroundColor: Color = Color.white.opacity(0.1), 
                   shadowColor: Color = .black.opacity(0.3)) -> some View {
        modifier(ModernCardStyle(backgroundColor: backgroundColor, shadowColor: shadowColor))
    }
}

// MARK: - Glassmorphism Style
struct GlassmorphismStyle: ViewModifier {
    let tintColor: Color?
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: tintColor?.opacity(0.2) ?? .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassmorphism(tintColor: Color? = nil) -> some View {
        modifier(GlassmorphismStyle(tintColor: tintColor))
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isRotating = false
    let text: String
    
    init(text: String = "Caricamento...") {
        self.text = text
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.blue, .purple, .blue]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isRotating
                )
                .onAppear {
                    isRotating = true
                }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Bounce Animation
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    func bounceEffect() -> some View {
        buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Badge View
struct BadgeView: View {
    let icon: String?
    let text: String
    let color: Color
    
    init(icon: String? = nil, text: String, color: Color) {
        self.icon = icon
        self.text = text
        self.color = color
    }
    
    init(count: Int, color: Color) {
        self.icon = nil
        self.text = "\(count)"
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color)
        .cornerRadius(8)
    }
}

// MARK: - Stat Card
struct StatCardView: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    let backgroundColor: Color?
    
    init(title: String, value: String, color: Color, icon: String, backgroundColor: Color? = nil) {
        self.title = title
        self.value = value
        self.color = color
        self.icon = icon
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassmorphism(tintColor: backgroundColor ?? .blue)
    }
}

// MARK: - Section Header
struct ModernSectionHeader: View {
    let title: String
    let icon: String?
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(title: String, 
         icon: String? = nil,
         actionTitle: String? = nil,
         action: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.blue)
            }
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
