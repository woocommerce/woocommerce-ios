import SwiftUI

struct ErrorBanner: View {

    let reason: String

    var body: some View {
        BannerShell(title: Localization.title, tone: .error) {
            Text(reason)
                .font(.assistantBody)
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "assistant.banner.error.title",
            value: "Something went wrong",
            comment: "Title shown above the inline error message in the AI Assistant chat"
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
#endif
