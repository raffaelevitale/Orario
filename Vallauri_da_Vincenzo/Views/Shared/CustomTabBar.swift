import SwiftUI

/// Barra di navigazione personalizzata in stile "pill" flottante con sole icone
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var settingsManager: SettingsManager
    @Namespace private var selectionAnimation
    
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }

    private struct TabItem: Identifiable {
        let id = UUID()
        let index: Int
        let title: String
        let icon: String
    }

    private var tabs: [TabItem] = [
        .init(index: 0, title: "Home", icon: "house.fill"),
        .init(index: 1, title: "Orario", icon: "calendar.day.timeline.left"),
        .init(index: 2, title: "Planner", icon: "calendar.badge.plus"),
        .init(index: 3, title: "Voti", icon: "chart.bar.doc.horizontal"),
        .init(index: 4, title: "Impostazioni", icon: "gearshape.fill")
    ]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(tabs) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = tab.index
                    }
                    HapticManager.shared.selection()
                } label: {
                    ZStack {
                        if selectedTab == tab.index {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.15))
                                .matchedGeometryEffect(id: "selected", in: selectionAnimation)
                                .frame(height: 40)
                        }

                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selectedTab == tab.index ? .white : .white.opacity(0.7))
                            .frame(width: 48, height: 40)
                            .contentShape(Rectangle())
                    }
                }
                .buttonStyle(BounceButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(blurBackground)
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .accessibilityElement(children: .contain)
    }

    private var blurBackground: some View {
        // Materiale sfocato + riflessi per un vero "liquid glass"
        ZStack {
            // Base blur
            Rectangle()
                .fill(.ultraThinMaterial)
            // Tonalità scura semi-trasparente per staccarsi dallo sfondo
            Rectangle()
                .fill(Color.black.opacity(0.18))
            // Highlight superiore per effetto vetro bagnato
            LinearGradient(
                colors: [Color.white.opacity(0.25), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .blendMode(.screen)
            // Leggero bagliore interno
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(colors: [
                        .white.opacity(0.35),
                        .white.opacity(0.08)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.8
                )
                .padding(0.5)
        }
    }
}

/// Pulsante flottante rotondo per la ricerca, in stile GitHub app
struct FloatingSearchButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black.opacity(0.85))
                .frame(width: 56, height: 56)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(BounceButtonStyle())
    }
}
