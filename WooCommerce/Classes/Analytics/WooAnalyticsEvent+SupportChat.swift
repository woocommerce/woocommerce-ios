import Foundation

extension WooAnalyticsEvent {
    enum SupportChat {
        private enum Key: String {
            case rating
        }

        static func feedbackSubmitted(upvoted: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatFeedbackSubmitted,
                              properties: [Key.rating.rawValue: upvoted ? "up" : "down"])
        }
    }
}
