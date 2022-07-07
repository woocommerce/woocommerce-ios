extension WooAnalyticsEvent {
    enum ImageUpload {
        /// Common event keys.
        private enum Keys {
            /// The type of the product - product or variation.
            static let productOrVariation = "type"
        }

        enum ProductOrVariation {
            case product
            case variation
        }

        /// Tracked when the product or variation is saved after none of the images are pending upload in the background.
        /// - Parameter productOrVariation: whether the save action is for a product or variation.
        static func savingProductAfterBackgroundImageUploadSuccess(productOrVariation: ProductOrVariation) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .savingProductAfterBackgroundImageUploadSuccess,
                              properties: [Keys.productOrVariation: productOrVariation.analyticsValue])
        }

        /// Tracked when the product cannot be saved after none of the images are pending upload in the background.
        /// - Parameter productOrVariation: whether the save action is for a product or variation.
        static func savingProductAfterBackgroundImageUploadFailed(productOrVariation: ProductOrVariation, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .savingProductAfterBackgroundImageUploadFailed,
                              properties: [Keys.productOrVariation: productOrVariation.analyticsValue],
                              error: error)
        }

        /// Tracked when a notice is shown from failure saving product after image upload in the background.
        /// - Parameter productOrVariation: whether the save action is for a product or variation.
        static func failureSavingProductAfterImageUploadNoticeShown(productOrVariation: ProductOrVariation) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .failureSavingProductAfterImageUploadNoticeShown,
                              properties: [Keys.productOrVariation: productOrVariation.analyticsValue])
        }

        /// Tracked when the user taps on a notice to view product details from failure saving product after image upload in the background.
        /// - Parameter productOrVariation: whether the save action is for a product or variation.
        static func failureSavingProductAfterImageUploadNoticeTapped(productOrVariation: ProductOrVariation) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .failureSavingProductAfterImageUploadNoticeTapped,
                              properties: [Keys.productOrVariation: productOrVariation.analyticsValue])
        }

        /// Tracked when a notice is shown from failure uploading an image in the background.
        /// - Parameter productOrVariation: whether the save action is for a product or variation.
        static func failureUploadingImageNoticeShown(productOrVariation: ProductOrVariation) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .failureUploadingImageNoticeShown,
                              properties: [Keys.productOrVariation: productOrVariation.analyticsValue])
        }

        /// Tracked when the user taps on a notice to view product details from failure uploading an image in the background.
        /// - Parameter productOrVariation: whether the save action is for a product or variation.
        static func failureUploadingImageNoticeTapped(productOrVariation: ProductOrVariation) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .failureUploadingImageNoticeTapped,
                              properties: [Keys.productOrVariation: productOrVariation.analyticsValue])
        }
    }
}

private extension WooAnalyticsEvent.ImageUpload.ProductOrVariation {
    var analyticsValue: String {
        switch self {
        case .product:
            return "product"
        case .variation:
            return "variation"
        }
    }
}
