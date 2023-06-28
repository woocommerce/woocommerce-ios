import Foundation

extension WooAnalyticsEvent {
    enum ProductSharingAI {
        private enum Key: String {
            case isRetry = "is_retry"
            case withMessage = "with_message"
            case isUseful = "is_useful"
        }

        static func sheetDisplayed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productSharingAIDisplayed,
                              properties: [:])
        }

        static func generateButtonTapped(isRetry: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productSharingAIGenerateTapped,
                              properties: [Key.isRetry.rawValue: isRetry])
        }

        static func shareButtonTapped(withMessage: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productSharingAIShareTapped,
                              properties: [Key.withMessage.rawValue: withMessage])
        }

        static func sheetDismissed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productSharingAIDismissed,
                              properties: [:])
        }

        static func messageGenerated() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productSharingAIMessageGenerated,
                              properties: [:])
        }

        static func messageGenerationFailed(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productSharingAIMessageGenerationFailed,
                              properties: [:],
                              error: error)
        }

        static func feedbackSent(isUseful: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productSharingAIFeedback,
                              properties: [Key.isUseful.rawValue: isUseful])
        }
    }
}
