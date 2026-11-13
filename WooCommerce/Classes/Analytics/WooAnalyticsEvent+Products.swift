import Networking

extension WooAnalyticsEvent {
    enum Products {
        /// Event property keys.
        private enum Key {
            static let productType = "product_type"
        }

        static func productListSelected() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListSelected, properties: [:])
        }

        static func productListReselected() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListReselected, properties: [:])
        }

        static func productListProductTapped(productType: ProductType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListProductTapped,
                              properties: [Key.productType: productType.rawValue])
        }
    }
}
