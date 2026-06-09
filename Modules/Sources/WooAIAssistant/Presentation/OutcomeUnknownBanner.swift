import SwiftUI

struct OutcomeUnknownBanner: View {

    let reason: String

    var body: some View {
        BannerShell(title: Localization.title, tone: .warning) {
            Text(reason)
                .font(.assistantBody)
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "assistant.banner.outcomeUnknown.title",
            value: "Outcome unknown",
            comment: "Banner title shown when an action's success cannot be confirmed"
        )
    }
}

#if DEBUG
#Preview("In chat") {
    AssistantChatView.preview(.outcomeUnknown)
}

#Preview("Standalone") {
    OutcomeUnknownBanner(reason: "The connection dropped before we got a confirmation.")
        .padding()
}
#endif
