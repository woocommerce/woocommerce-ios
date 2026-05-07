import SwiftUI

struct SupportChatFeedbackRow: View {
    let messageID: Int64
    let hasRated: Bool
    let onRate: (Bool) -> Void

    @State private var selectedUpvoted: Bool?

    var body: some View {
        HStack(spacing: SupportChatLayout.bubblePadding) {
            if hasRated || selectedUpvoted != nil {
                ratedState
            } else {
                unratedState
            }
            Spacer()
        }
        .padding(.leading, SupportChatLayout.bubblePadding)
    }

    private var unratedState: some View {
        HStack(spacing: 12) {
            Button {
                submitRating(upvoted: true)
            } label: {
                Image(systemName: "hand.thumbsup")
                    .foregroundColor(Color(.secondaryLabel))
            }
            .accessibilityLabel(Localization.rateHelpful)

            Button {
                submitRating(upvoted: false)
            } label: {
                Image(systemName: "hand.thumbsdown")
                    .foregroundColor(Color(.secondaryLabel))
            }
            .accessibilityLabel(Localization.rateNotHelpful)
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private var ratedState: some View {
        let upvoted = selectedUpvoted ?? true
        HStack(spacing: 6) {
            Image(systemName: upvoted ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                .foregroundColor(Color(.accent))
            Text(upvoted ? Localization.helpful : Localization.notHelpful)
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    private func submitRating(upvoted: Bool) {
        selectedUpvoted = upvoted
        onRate(upvoted)
    }
}

private extension SupportChatFeedbackRow {
    enum Localization {
        static let rateHelpful = NSLocalizedString(
            "supportChatFeedbackRow.rateHelpful",
            value: "Rate helpful",
            comment: "Accessibility label for thumbs up button to rate bot response as helpful"
        )
        static let rateNotHelpful = NSLocalizedString(
            "supportChatFeedbackRow.rateNotHelpful",
            value: "Rate not helpful",
            comment: "Accessibility label for thumbs down button to rate bot response as not helpful"
        )
        static let helpful = NSLocalizedString(
            "supportChatFeedbackRow.helpful",
            value: "Helpful",
            comment: "Message shown after user rates a bot response as helpful"
        )
        static let notHelpful = NSLocalizedString(
            "supportChatFeedbackRow.notHelpful",
            value: "Not helpful",
            comment: "Message shown after user rates a bot response as not helpful"
        )
    }
}

#Preview("Unrated") {
    SupportChatFeedbackRow(
        messageID: 123,
        hasRated: false,
        onRate: { _ in }
    )
    .padding()
}

#Preview("Rated") {
    SupportChatFeedbackRow(
        messageID: 123,
        hasRated: true,
        onRate: { _ in }
    )
    .padding()
}
