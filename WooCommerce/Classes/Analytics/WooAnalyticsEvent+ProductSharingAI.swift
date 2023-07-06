import Foundation

extension WooAnalyticsEvent {
    enum ProductSharingAI {
        private enum Key: String {
            case isRetry = "is_retry"
            case withMessage = "with_message"
            case language = "language"
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

        static func identifiedLanguage(_ identifiedLanguage: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productSharingAIIdentifyLanguageSuccess,
                              properties: [Key.language.rawValue: identifiedLanguage])
        }

        static func identifyLanguageFailed(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productSharingAIIdentifyLanguageFailed,
                              properties: [:],
                              error: error)
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
    }
}
