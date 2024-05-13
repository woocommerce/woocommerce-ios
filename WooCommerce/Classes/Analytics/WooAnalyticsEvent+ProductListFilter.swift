extension WooAnalyticsEvent {
    enum ProductListFilter {
        /// Event property keys.
        private enum Key {
            static let source = "source"
            static let filters = "filters"
            static let type = "type"
        }

        /// Tracked when the user taps on the button to filter products.
        /// - Parameter source: Source of the product list filter.
        static func productListViewFilterOptionsTapped(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListViewFilterOptionsTapped,
                              properties: [Key.source: source.rawValue])
        }

        /// Tracked when the user taps on the button to show products after the filters screen.
        /// - Parameter source: Source of the product list filter.
        /// - Parameter filters: Filters for the products.
        static func productFilterListShowProductsButtonTapped(source: Source, filters: FilterProductListViewModel.Filters) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productFilterListShowProductsButtonTapped,
                              properties: [Key.source: source.rawValue,
                                           Key.filters: filters.analyticsDescription])
        }

        static func productFilterListExploreButtonTapped(type: PromotableProductType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productFilterListExploreButtonTapped, properties: [Key.type: type.rawValue])
        }
    }
}

extension WooAnalyticsEvent.ProductListFilter {
    /// Trigger of the product list filter. The raw value is the event property value.
    enum Source: String {
        /// From the products tab.
        case productsTab = "products_tab"
        /// From order form > add products.
        case orderForm = "order_form"
        /// From coupon form > products.
        case couponForm = "coupon_form"
        /// From coupon form > usage restrictions > exclude products.
        case couponRestrictions = "coupon_restrictions"
        /// From Blaze campaign creation flow
        case blaze = "blaze"
        /// From orders > filter.
        case orderFilter = "order_filter"
    }
}
