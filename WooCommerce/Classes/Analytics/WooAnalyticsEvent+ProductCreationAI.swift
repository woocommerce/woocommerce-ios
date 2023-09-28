import Foundation

extension WooAnalyticsEvent {
    enum ProductCreationAI {
        private enum Key: String {
            case value = "value"
        }

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

        static func aiToneSelected(_ tone: AIToneVoice) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAIToneSelected,
                              properties: [Key.value.rawValue: tone.rawValue])
        }
    }
}
