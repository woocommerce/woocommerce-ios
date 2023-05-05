extension WooAnalyticsEvent {
    enum ProductFormAI {
        /// Event property keys.
        private enum Key {
            static let source = "source"
            static let isRetry = "is_retry"
        }

        /// Tracked when the user taps on the button to start the product description AI flow.
        static func productDescriptionAIButtonTapped(source: ProductDescriptionAISource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDescriptionAIButtonTapped,
                              properties: [Key.source: source.rawValue])
        }

        /// Tracked when the user taps on the button to generate a product description with AI.
        /// - Parameter isRetry: Whether the user has generated a description in the same session before.
        static func productDescriptionAIGenerateButtonTapped(isRetry: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDescriptionAIGenerateButtonTapped,
                              properties: [Key.isRetry: isRetry])
        }

        /// Tracked when the user taps on the button to pause the product description generation with AI.
        static func productDescriptionAIPauseButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDescriptionAIPauseButtonTapped, properties: [:])
        }

        /// Tracked when the user taps on the button to apply the AI-generated product description to the product.
        static func productDescriptionAIApplyButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDescriptionAIApplyButtonTapped, properties: [:])
        }

        /// Tracked when the user taps on the button to copy the AI-generated product description.
        static func productDescriptionAICopyButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDescriptionAICopyButtonTapped, properties: [:])
        }

        /// Tracked when the product description AI generation succeeds.
        static func productDescriptionAIGenerationSuccess() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDescriptionAIGenerationSuccess, properties: [:])
        }

        /// Tracked when the product description AI generation fails.
        static func productDescriptionAIGenerationFailed(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDescriptionAIGenerationFailed, properties: [:], error: error)
        }
    }
}

extension WooAnalyticsEvent.ProductFormAI {
    /// Trigger of the product description AI flow. The raw value is the event property value.
    enum ProductDescriptionAISource: String {
        /// From product description Aztec editor.
        case aztecEditor = "aztec_editor"
    }
}
