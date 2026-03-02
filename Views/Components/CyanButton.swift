import SwiftUI

struct CyanButton: View {
    let title: String
    var icon: String? = nil
    var style: ButtonStyle = .primary
    let action: () -> Void

    enum ButtonStyle {
        case primary
        case secondary
        case outline
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(backgroundView)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AegisTheme.buttonCornerRadius))
            .overlay(overlayView)
        }
        .cyanGlow(radius: style == .primary ? 8 : 0, opacity: style == .primary ? 0.3 : 0)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            AegisTheme.cyan
        case .secondary:
            AegisTheme.cyan.opacity(0.15)
        case .outline:
            Color.clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: .black
        case .secondary: AegisTheme.cyan
        case .outline: AegisTheme.cyan
        }
    }

    @ViewBuilder
    private var overlayView: some View {
        switch style {
        case .outline:
            RoundedRectangle(cornerRadius: AegisTheme.buttonCornerRadius)
                .strokeBorder(AegisTheme.cyan.opacity(0.5), lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

struct AegisCardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .aegisCard()
    }
}
