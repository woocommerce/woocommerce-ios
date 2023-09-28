import Foundation

extension WooAnalyticsEvent {
    enum ProductNameAI {
        enum EntryPointSource: String {
            case productCreationAI = "product_creation_ai"
        }

        private enum Key: String {
            case source = "source"
            case isRetry = "is_retry"
            case hasInputName = "has_input_name"
            case language = "language"
        }

        static func entryPointTapped(hasInputName: Bool, source: EntryPointSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productNameAIEntryPointTapped,
                              properties: [
                                Key.hasInputName.rawValue: hasInputName,
                                Key.source.rawValue: source.rawValue
                              ])
        }

        static func generateButtonTapped(isRetry: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productNameAIGenerateButtonTapped,
                              properties: [Key.isRetry.rawValue: isRetry])
        }

        static func copyButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productNameAICopyButtonTapped,
                              properties: [:])
        }

        static func applyButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productNameAIApplyButtonTapped,
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
