import SwiftUI

struct IterationCapBanner: View {

    var body: some View {
        BannerShell(title: Localization.title, tone: .info) {
            Text(Localization.body)
                .font(.assistantBody)
                .foregroundStyle(Color.assistantBubbleAssistantText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "assistant.banner.iterationCap.title",
            value: "Reached step limit",
            comment: "Title for the banner shown when the assistant hits its iteration cap"
        )
        static let body = NSLocalizedString(
            "assistant.banner.iterationCap.body",
            value: "I had to stop short of finishing. Send a follow-up to continue or refine the question.",
            comment: "Body for the iteration-cap banner"
        )
    }
}

#if DEBUG
#Preview("In chat") {
    AssistantChatView.preview(.iterationCap)
}

#Preview("Standalone") {
    IterationCapBanner()
        .padding()
}
#endif
