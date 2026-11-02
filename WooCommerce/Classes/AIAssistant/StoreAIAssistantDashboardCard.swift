import StoreDesignSystem
import SwiftUI
import Yosemite

struct StoreAIAssistantDashboardCard: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var isPresentingChat = false

    let site: Site

    var body: some View {
        Button(action: presentChat) {
            StoreDashboardCardSurface {
                HStack(spacing: StoreSpacing.s4) {
                    sparkleChip

                    Text(Localization.placeholder)
                        .storeTextStyle(.bodyLarge)
                        .foregroundStyle(.storeOnSurface)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    sendAffordance
                }
                .padding(.horizontal, StorePadding.p5)
                .padding(.vertical, StorePadding.p4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Localization.accessibilityLabel)
        .fullScreenCover(isPresented: $isPresentingChat) {
            AIAssistantChatScreen(site: site, onClose: dismissChat)
        }
    }

    private var sparkleChip: some View {
        StoreIcon.Sparkles.regular.image(size: .large)
            .foregroundStyle(.storeOnSecondaryContainer)
            .phaseAnimator([false, true]) { content, isHighlighted in
                content
                    .scaleEffect(accessibilityReduceMotion || isHighlighted ? 1 : Layout.sparkleMinimumScale)
                    .opacity(accessibilityReduceMotion || isHighlighted ? 1 : Layout.sparkleMinimumOpacity)
            } animation: { _ in
                .easeInOut(duration: Layout.sparkleAnimationDuration)
            }
            .frame(width: StoreSpacing.s9, height: StoreSpacing.s9)
            .background(Color.storeSecondaryContainer)
            .clipShape(.rect(cornerRadius: StoreRadius.medium))
            .accessibilityHidden(true)
    }

    private var sendAffordance: some View {
        StoreIcon.ArrowUp.regular.image(size: .medium)
            .foregroundStyle(.storeOnPrimary)
            .frame(width: StoreSpacing.s8, height: StoreSpacing.s8)
            .background(Color.storePrimary)
            .clipShape(.circle)
            .accessibilityHidden(true)
    }

    private func presentChat() {
        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .aiAssistant))
        isPresentingChat = true
    }

    private func dismissChat() {
        isPresentingChat = false
    }
}

private extension StoreAIAssistantDashboardCard {
    enum Layout {
        static let sparkleMinimumScale: CGFloat = 0.95
        static let sparkleMinimumOpacity = 0.6
        static let sparkleAnimationDuration = 0.8
    }

    enum Localization {
        static let placeholder = NSLocalizedString(
            "dashboardCard.aiAssistant.placeholder",
            value: "Ask about your store…",
            comment: "Placeholder text on the AI Assistant entry card on the dashboard, styled like a chat input."
        )
        static let accessibilityLabel = NSLocalizedString(
            "dashboardCard.aiAssistant.accessibilityLabel",
            value: "Open the AI assistant",
            comment: "Accessibility label for the AI Assistant entry card on the dashboard."
        )
    }
}
