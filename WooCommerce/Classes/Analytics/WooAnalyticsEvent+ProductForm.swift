extension WooAnalyticsEvent {
    enum ProductForm {
        /// Event property keys.
        private enum Key {
            static let source = "source"
        }

        /// Tracked when the user taps on the button to share a product.
        static func productDetailShareButtonTapped(source: ShareProductSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDetailShareButtonTapped,
                              properties: [Key.source: source.rawValue])
        }
    }
}

extension WooAnalyticsEvent.ProductForm {
    /// Source of the share product action. The raw value is the event property value.
    enum ShareProductSource: String {
        /// From product form in the navigation bar.
        case productForm = "product_form"
        /// From product form > more menu in the navigation bar.
        case moreMenu = "more_menu"
    }
}
