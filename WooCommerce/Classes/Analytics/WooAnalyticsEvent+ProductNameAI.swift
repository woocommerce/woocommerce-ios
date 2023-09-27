import Foundation

extension WooAnalyticsEvent {
    enum ProductNameAI {
        private enum Key: String {
            case source = "source"
            case isRetry = "is_retry"
            case withMessage = "with_message"
            case language = "language"
        }

        static func entryPointTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productNameAIEntryPointTapped,
                              properties: [:])
        }

        static func generateButtonTapped(isRetry: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productNameAIGenerateButtonTapped,
                              properties: [Key.isRetry.rawValue: isRetry])
        }

        static func copyButtonTapped(withMessage: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productNameAICopyButtonTapped,
                              properties: [Key.withMessage.rawValue: withMessage])
        }

        static func applyButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productNameAICopyButtonTapped,
                              properties: [:])
        }

        static func identifiedLanguage(_ identifiedLanguage: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .identifyLanguageSuccess,
                              properties: [Key.language.rawValue: identifiedLanguage,
                                           Key.source.rawValue: Constants.productNameSource])
        }

        static func identifyLanguageFailed(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .identifyLanguageFailed,
                              properties: [Key.source.rawValue: Constants.productNameSource],
                              error: error)
        }

        static func nameGenerated() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productNameAIGenerationSuccess,
                              properties: [:])
        }

        static func nameGenerationFailed(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productNameAIGenerationFailed,
                              properties: [:],
                              error: error)
        }
    }
}

private extension WooAnalyticsEvent.ProductNameAI {
    enum Constants {
        static let productNameSource = "product_name"
    }
}
