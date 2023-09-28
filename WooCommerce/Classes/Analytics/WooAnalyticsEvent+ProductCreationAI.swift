import Foundation

extension WooAnalyticsEvent {
    enum ProductCreationAI {
        static func entryPointDisplayed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAIEntryPointDisplayed,
                              properties: [:])
        }

        static func entryPointTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAIEntryPointTapped,
                              properties: [:])
        }

        static func productNameContinueTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAIProductNameContinueTapped,
                              properties: [:])
        }
    }
}
