import Foundation
import struct WooFoundation.WooAnalyticsEvent

extension WooAnalyticsEvent {
    enum ProductCreationAI {
        private enum Key: String {
            case value = "value"
            case isFirstAttempt = "is_first_attempt"
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
                              properties: [Key.value.rawValue: tone.rawValue.lowercased()])
        }

        static func generateDetailsTapped(isFirstAttempt: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAIGenerateDetailsTapped,
                              properties: [Key.isFirstAttempt.rawValue: isFirstAttempt])
        }

        static func generateProductDetailsSuccess() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAIGenerateProductDetailsSuccess,
                              properties: [:])
        }

        static func generateProductDetailsFailed(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAIGenerateProductDetailsFailed,
                              properties: [:],
                              error: error)
        }

        static func saveAsDraftButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAISaveAsDraftButtonTapped,
                              properties: [:])
        }

        static func saveAsDraftSuccess() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAISaveAsDraftSuccess,
                              properties: [:])
        }

        static func saveAsDraftFailed(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAISaveAsDraftFailed,
                              properties: [:],
                              error: error)
        }

        enum Survey {
            static func confirmationViewDisplayed() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .productCreationAISurveyConfirmationViewDisplayed,
                                  properties: [:])
            }

            static func startSurvey() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .productCreationAISurveyStartSurveyButtonTapped,
                                  properties: [:])
            }

            static func skip() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .productCreationAISurveySkipButtonTapped,
                                  properties: [:])
            }
        }
    }
}
