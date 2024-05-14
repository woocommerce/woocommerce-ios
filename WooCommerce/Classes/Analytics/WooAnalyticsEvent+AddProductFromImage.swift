import Foundation

extension WooAnalyticsEvent {
    enum AddProductFromImage {
        /// Event property keys.
        private enum Key {
            static let source = "source"
            static let scannedTextCount = "scanned_text_count"
            static let language = "language"
            static let selectedTextCount = "selected_text_count"
            static let isNameEmpty = "is_name_empty"
            static let isDescriptionEmpty = "is_description_empty"
            static let hasScannedText = "has_scanned_text"
            static let hasGeneratedDetails = "has_generated_details"
        }

        /// Tracked when the user launches the screen to add a product from an image.
        /// - Parameters:
        ///   - source: Entry point to product creation.
        ///
        static func formDisplayed(source: AddProductCoordinator.Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addProductFromImageDisplayed, properties: [Key.source: source.analyticsValue])
        }

        /// Tracked when the image scanning completes.
        /// - Parameters:
        ///   - source: Entry point to product creation.
        ///   - scannedTextCount: number of text scanned.
        ///
        static func scanCompleted(source: AddProductCoordinator.Source, scannedTextCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addProductFromImageScanCompleted, properties: [
                Key.source: source.analyticsValue,
                Key.scannedTextCount: scannedTextCount
            ])
        }

        /// Tracked when the image scanning fails.
        /// - Parameters:
        ///   - source: Entry point to product creation.
        ///   - error: Detail of the failure.
        ///
        static func scanFailed(source: AddProductCoordinator.Source, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addProductFromImageScanFailed, properties: [Key.source: source.analyticsValue], error: error)
        }

        /// Tracked when AI identifies a language from scanned text of an image.
        /// - Parameters:
        ///   - identifiedLanguage: Language detected in the text by AI.
        ///
        static func identifiedLanguage(_ identifiedLanguage: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .identifyLanguageSuccess,
                              properties: [
                                Key.source: Constants.productDetailsFromScannedTextsSource,
                                Key.language: identifiedLanguage
                              ])
        }

        /// Tracked when AI fails to identify a language from scanned text of an image.
        /// - Parameters:
        ///   - error: Detail of the failure.
        ///
        static func identifyLanguageFailed(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .identifyLanguageFailed,
                              properties: [Key.source: Constants.productDetailsFromScannedTextsSource],
                              error: error)
        }

        /// Tracked when product details are generated from the scanned text of an image.
        /// - Parameters:
        ///   - source: Entry point to product creation.
        ///   - language: Language detected in the text by AI.
        ///   - selectedTextCount: The number of selected text for generating the product details.
        ///
        static func detailsGenerated(source: AddProductCoordinator.Source, language: String, selectedTextCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addProductFromImageDetailsGenerated, properties: [
                Key.source: source.analyticsValue,
                Key.language: language,
                Key.selectedTextCount: selectedTextCount
            ])
        }

        /// Tracked when product detail generation from the scanned text of an image failed.
        /// - Parameters:
        ///   - source: Entry point to product creation.
        ///   - error: Detail of the failure.
        ///
        static func detailGenerationFailed(source: AddProductCoordinator.Source, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addProductFromImageDetailGenerationFailed, properties: [Key.source: source.analyticsValue], error: error)
        }

        /// Tracked when the user taps to continue from adding a product with an image to the main product creation form.
        /// - Parameters:
        ///   - source: Entry point to product creation.
        ///   - isNameEmpty: Whether the name field is empty.
        ///   - isDescriptionEmpty: Whether the description field is empty.
        ///   - hasScannedText: Whether the image has any scanned text.
        ///   - hasGeneratedDetails: Whether the name/description has been populated with AI-generated details.
        ///
        static func continueButtonTapped(source: AddProductCoordinator.Source,
                                         isNameEmpty: Bool,
                                         isDescriptionEmpty: Bool,
                                         hasScannedText: Bool,
                                         hasGeneratedDetails: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addProductFromImageContinueButtonTapped, properties: [
                Key.source: source.analyticsValue,
                Key.isNameEmpty: isNameEmpty,
                Key.isDescriptionEmpty: isDescriptionEmpty,
                Key.hasScannedText: hasScannedText,
                Key.hasGeneratedDetails: hasGeneratedDetails
            ])
        }
    }
}

private extension WooAnalyticsEvent.AddProductFromImage {
    enum Constants {
        static let productDetailsFromScannedTextsSource = "product_details_from_scanned_texts"
    }
}
