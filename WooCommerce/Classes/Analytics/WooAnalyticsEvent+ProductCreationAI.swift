import Foundation
import WooFoundation

extension WooAnalyticsEvent {
    enum ProductCreationAI {
        private enum Key: String {
            case value
            case isFirstAttempt = "is_first_attempt"
            case numberOfTexts = "number_of_texts"
            case name
            case shortDescription = "short_description"
            case description
            case field
            case featureWordCount = "feature_word_count"
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

        static func generateDetailsTapped(isFirstAttempt: Bool,
                                          features: String) -> WooAnalyticsEvent {
            let wordCount = features.components(separatedBy: .whitespacesAndNewlines).count
            return WooAnalyticsEvent(statName: .productCreationAIGenerateDetailsTapped,
                                     properties: [Key.isFirstAttempt.rawValue: isFirstAttempt,
                                                  Key.featureWordCount.rawValue: wordCount])
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

        /// When the user taps on the “Read text from product photo” button or the “Replace photo” button
        static func packagePhotoSelectionFlowStarted() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAIStartedPackagePhotoSelectionFlow, properties: [:])
        }

        /// Finished detecting text from the package photo
        static func packagePhotoTextDetected(wordCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAITextDetected, properties: [Key.numberOfTexts.rawValue: wordCount])
        }

        /// When text detection fails
        static func packagePhotoTextDetectionFailed(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAITextDetectionFailed, properties: [:], error: error)
        }

        /// Upon successfully generating options of Name, Summary and Description fields.
        static func nameDescriptionOptionsGenerated(nameCount: Int,
                                                    shortDescriptionCount: Int,
                                                    descriptionCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAIGeneratedNameDescriptionOptions,
                              properties: [
                                Key.name.rawValue: nameCount,
                                Key.shortDescription.rawValue: shortDescriptionCount,
                                Key.description.rawValue: descriptionCount
                              ])
        }

        /// When the user taps on the “Undo edits” button
        static func undoEditTapped(for field: ProductDetailPreviewViewModel.EditableField) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productCreationAIUndoEditTapped, properties: [Key.field.rawValue: field.rawValue])
        }
    }
}
