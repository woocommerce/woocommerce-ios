import SwiftUI
import Yosemite

struct AIAssistantDashboardCard: View {

    let site: Site

    @State private var isPresentingChat: Bool = false
    @Namespace private var cardNamespace

    var body: some View {
        Button {
            isPresentingChat = true
        } label: {
            HStack(spacing: 12) {
                glyph
                Text(Localization.placeholder)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                sendButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 64)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
            .matchedGeometryEffect(id: Self.transitionID, in: cardNamespace)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Localization.accessibilityLabel)
        .fullScreenCover(isPresented: $isPresentingChat) {
            AIAssistantChatScreen(site: site, onClose: { isPresentingChat = false })
        }
    }

    private var glyph: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.accentColor.opacity(0.14))
            Image(systemName: "sparkles")
                .symbolRenderingMode(.monochrome)
                .symbolEffect(.variableColor.iterative.reversing,
                              options: .repeating.speed(0.4))
                .foregroundStyle(Color.accentColor)
                .font(.system(size: 22, weight: .semibold))
        }
        .frame(width: 48, height: 48)
    }

    private var sendButton: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
            Image(systemName: "arrow.up")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 36, height: 36)
        .accessibilityHidden(true)
    }

    private static let transitionID = "ai-assistant-card"

    private enum Localization {
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
