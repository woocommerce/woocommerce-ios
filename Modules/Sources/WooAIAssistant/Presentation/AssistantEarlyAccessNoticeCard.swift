import SwiftUI
import WooFoundation

struct AssistantEarlyAccessNoticeCard: View {

    let onFeedbackTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AssistantSpacing.large) {
            Text(Localization.pill)
                .font(.caption.weight(.heavy))
                .tracking(0.6)
                .foregroundStyle(Color.assistantOnAccent)
                .padding(.horizontal, AssistantSpacing.small)
                .padding(.vertical, AssistantSpacing.xSmall)
                .background(
                    RoundedRectangle(cornerRadius: AssistantRadius.badge)
                        .fill(Color(.accent))
                )

            Text(Localization.body)
                .font(.assistantSubheadline)
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onFeedbackTap) {
                HStack(spacing: AssistantSpacing.small) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: Layout.iconSize, weight: .semibold))
                    Text(Localization.feedbackCTA)
                        .font(.assistantSubheadlineEmphasized)
                }
                .foregroundStyle(Color.primary)
                .padding(.horizontal, AssistantSpacing.medium)
                .padding(.vertical, AssistantSpacing.small)
                .background(
                    RoundedRectangle(cornerRadius: AssistantRadius.button)
                        .fill(Color(.secondaryButtonBackground))
                )
            }
            .buttonStyle(AssistantPressableButtonStyle())
        }
        .padding(AssistantSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AssistantRadius.card)
                .fill(Color(Layout.cardBackground))
        )
    }

    private enum Layout {
        static let iconSize: CGFloat = 13

        // Light mode uses the lightest WooCommerce purple from the design system;
        // dark mode matches the suggestion card surface for visual consistency.
        static let cardBackground = UIColor { traits in
            switch traits.userInterfaceStyle {
            case .dark:
                return .listForeground(modal: false)
            default:
                return .withColorStudio(.wooCommercePurple, shade: .shade0)
            }
        }
    }

    private enum Localization {
        static let pill = NSLocalizedString(
            "assistantChat.empty.earlyAccess.pill",
            value: "EARLY ACCESS",
            comment: "Pill label indicating the AI Assistant is in early access"
        )
        static let body = NSLocalizedString(
            "assistantChat.empty.earlyAccess.body",
            value: "Hi! We're just getting started, with more on the way. Let us know what's missing and what you'd love help with!",
            comment: "Body copy for the AI Assistant early access notice card"
        )
        static let feedbackCTA = NSLocalizedString(
            "assistantChat.empty.earlyAccess.feedbackCTA",
            value: "Feedback & requests",
            comment: "Button label opening the AI Assistant feedback survey"
        )
    }
}

#if DEBUG
#Preview {
    AssistantEarlyAccessNoticeCard(onFeedbackTap: {})
        .padding()
        .background(Color.assistantSurface)
}
#endif
