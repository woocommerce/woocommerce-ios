import SwiftUI

struct SupportChatFeedbackRow: View {
    let messageID: Int64
    /// The rating direction if the message has been rated (true = upvoted, false = downvoted), or nil if unrated.
    let rating: Bool?
    let onRate: (Bool) -> Void

    var body: some View {
        HStack(spacing: SupportChatLayout.bubblePadding) {
            if let rating {
                ratedState(upvoted: rating)
            } else {
                unratedState
            }
            Spacer()
        }
        .padding(.leading, SupportChatLayout.bubblePadding)
    }

    private var unratedState: some View {
        HStack {
            Button {
                onRate(true)
            } label: {
                Image(systemName: "hand.thumbsup")
                    .foregroundColor(Color(.secondaryLabel))
            }
            .accessibilityLabel(Localization.rateHelpful)

            Button {
                onRate(false)
            } label: {
                Image(systemName: "hand.thumbsdown")
                    .foregroundColor(Color(.secondaryLabel))
            }
            .accessibilityLabel(Localization.rateNotHelpful)
        }
        .font(.subheadline)
    }

    private func ratedState(upvoted: Bool) -> some View {
        Label {
            Text(upvoted ? Localization.helpful : Localization.notHelpful)
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
        } icon: {
            Image(systemName: upvoted ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                .foregroundColor(Color(.accent))
        }
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
        rating: nil,
        onRate: { _ in }
    )
    .padding()
}

#Preview("Rated Helpful") {
    SupportChatFeedbackRow(
        messageID: 123,
        rating: true,
        onRate: { _ in }
    )
    .padding()
}

#Preview("Rated Not Helpful") {
    SupportChatFeedbackRow(
        messageID: 123,
        rating: false,
        onRate: { _ in }
    )
    .padding()
}
