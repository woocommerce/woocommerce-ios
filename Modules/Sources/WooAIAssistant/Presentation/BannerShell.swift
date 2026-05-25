import SwiftUI

enum BannerTone {
    case error
    case warning
    case info
    case neutral
}

struct BannerShell<Content: View>: View {

    let title: String
    let tone: BannerTone
    var eyebrow: String?
    var eyebrowSymbol: String?
    let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    init(title: String,
         tone: BannerTone,
         eyebrow: String? = nil,
         eyebrowSymbol: String? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.tone = tone
        self.eyebrow = eyebrow
        self.eyebrowSymbol = eyebrowSymbol
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AssistantSpacing.small) {
            if let eyebrow {
                eyebrowLabel(text: eyebrow)
            }
            Text(title)
                .font(.assistantBodyEmphasized)
                .foregroundStyle(titleColor)

            content()
        }
        .padding(AssistantSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AssistantRadius.medium)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private func eyebrowLabel(text: String) -> some View {
        HStack(spacing: AssistantSpacing.xSmall) {
            if let eyebrowSymbol {
                Image(systemName: eyebrowSymbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(eyebrowColor)
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundStyle(eyebrowColor)
        }
    }

    private var titleColor: Color {
        switch tone {
        case .error: return Color.assistantError
        case .warning: return Color.primary
        case .info: return Color.assistantInfo
        case .neutral: return Color.primary
        }
    }

    private var eyebrowColor: Color {
        switch tone {
        case .error: return Color.assistantError
        case .warning: return Color.assistantWarning
        case .info: return Color.assistantInfo
        case .neutral: return Color.assistantMuted
        }
    }

    private var tintOpacity: CGFloat {
        colorScheme == .dark ? 0.08 : 0.16
    }

    private var backgroundColor: Color {
        switch tone {
        case .error: return Color.assistantError.opacity(tintOpacity)
        case .warning: return Color.assistantWarning.opacity(tintOpacity)
        case .info: return Color.assistantInfo.opacity(tintOpacity)
        case .neutral: return Color.assistantSurfaceElevated
        }
    }

    private var borderColor: Color {
        switch tone {
        case .error: return Color.assistantError.opacity(0.25)
        case .warning: return Color.assistantWarning.opacity(0.35)
        case .info: return Color.assistantInfo.opacity(0.25)
        case .neutral: return Color.assistantSurfaceBorder
        }
    }
}

#if DEBUG
#Preview("Error") {
    BannerShell(title: "Something went wrong", tone: .error) {
        Text("Network is unreachable. Try again in a moment.")
            .font(.assistantBody)
    }
    .padding()
}

#Preview("Warning") {
    BannerShell(title: "Outcome unknown", tone: .warning) {
        Text("The connection dropped before we got a confirmation.")
            .font(.assistantBody)
    }
    .padding()
}

#Preview("Info") {
    BannerShell(title: "Reached step limit", tone: .info) {
        Text("I had to stop short of finishing.")
            .font(.assistantBody)
    }
    .padding()
}
#endif
