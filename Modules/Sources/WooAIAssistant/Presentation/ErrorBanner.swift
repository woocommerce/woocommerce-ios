import SwiftUI

struct ErrorBanner: View {

    let reason: String
    var onRetry: (() -> Void)?

    var body: some View {
        BannerShell(title: Localization.title, tone: .error) {
            VStack(alignment: .leading, spacing: AssistantSpacing.small) {
                Text(reason)
                    .font(.assistantBody)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if let onRetry {
                    Button(action: onRetry) {
                        Text(Localization.retry)
                            .font(.assistantBodyEmphasized)
                            .foregroundStyle(Color.assistantError)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Localization.retryAccessibility)
                }
            }
        }
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "assistant.banner.error.title",
            value: "Something went wrong",
            comment: "Title shown above the inline error message in the AI Assistant chat"
        )
        static let retry = NSLocalizedString(
            "assistant.banner.error.retry",
            value: "Retry",
            comment: "Button on the AI Assistant inline error banner to re-send the failed prompt"
        )
        static let retryAccessibility = NSLocalizedString(
            "assistant.banner.error.retry.accessibility",
            value: "Retry the previous message",
            comment: "Accessibility label for the Retry button on the AI Assistant inline error banner"
        )
    }
}

#if DEBUG
#Preview("In chat") {
    AssistantChatView.preview(.failedMidStream)
}

#Preview("Standalone") {
    ErrorBanner(reason: "Network is unreachable. Try again in a moment.")
        .padding()
}

#Preview("With Retry") {
    ErrorBanner(reason: "Network is unreachable. Try again in a moment.", onRetry: {})
        .padding()
}
#endif
