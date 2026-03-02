import SwiftUI

enum AegisTheme {
    // MARK: - Colors
    static let cyan = Color(hex: 0x00FFFF)
    static let orange = Color(hex: 0xFF9500)
    static let background = Color(hex: 0x0A0A0A)
    static let backgroundDeep = Color(hex: 0x050505)
    static let cardBackground = Color(hex: 0x111111)
    static let surface = Color(hex: 0x1A1A1A)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textMuted = Color.white.opacity(0.4)
    static let danger = Color(hex: 0xFF3B30)
    static let success = Color(hex: 0x34C759)

    // MARK: - Gradients
    static let cardGradient = LinearGradient(
        colors: [cyan.opacity(0.05), Color.black.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cyanGlow = LinearGradient(
        colors: [cyan.opacity(0.6), cyan.opacity(0.2)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Modifiers
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12

    // MARK: - Glow Effect
    static func glowShadow(color: Color = cyan, radius: CGFloat = 10, opacity: Double = 0.3) -> some View {
        Color.clear.shadow(color: color.opacity(opacity), radius: radius)
    }
}

// MARK: - View Modifiers

struct AegisCardStyle: ViewModifier {
    var borderColor: Color = AegisTheme.cyan.opacity(0.2)

    func body(content: Content) -> some View {
        content
            .background(AegisTheme.cardGradient)
            .clipShape(RoundedRectangle(cornerRadius: AegisTheme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AegisTheme.cardCornerRadius)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
    }
}

struct CyanGlowStyle: ViewModifier {
    var radius: CGFloat = 10
    var opacity: Double = 0.3

    func body(content: Content) -> some View {
        content
            .shadow(color: AegisTheme.cyan.opacity(opacity), radius: radius)
    }
}

extension View {
    func aegisCard(borderColor: Color = AegisTheme.cyan.opacity(0.2)) -> some View {
        modifier(AegisCardStyle(borderColor: borderColor))
    }

    func cyanGlow(radius: CGFloat = 10, opacity: Double = 0.3) -> some View {
        modifier(CyanGlowStyle(radius: radius, opacity: opacity))
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
