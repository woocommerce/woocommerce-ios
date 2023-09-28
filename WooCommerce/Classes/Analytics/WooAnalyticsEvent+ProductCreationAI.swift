import Foundation

extension WooAnalyticsEvent {
    enum ProductCreationAI {
        static func entryPointDisplayed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAIEntryPointDisplayed,
                              properties: [:])
        }

        static func entryPointTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productNameAIEntryPointTapped,
                              properties: [:])
        }
    }
}
