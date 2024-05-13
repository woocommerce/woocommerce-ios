import Foundation

extension WooAnalyticsEvent {
    enum AIFeedback {
        /// Event property keys.
        private enum Key: String {
            case isUseful = "is_useful"
            case source
        }

        /// Source of the feedback.
        enum Source: String {
            case productDescription = "product_description"
            case productSharingMessage = "product_sharing_message"
            case productCreation = "product_creation"
        }

        /// Tracked when feedback for AI-generated content in sent.
        static func feedbackSent(source: Source, isUseful: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productAIFeedback,
                              properties: [Key.isUseful.rawValue: isUseful,
                                           Key.source.rawValue: source.rawValue])
        }
    }
}
