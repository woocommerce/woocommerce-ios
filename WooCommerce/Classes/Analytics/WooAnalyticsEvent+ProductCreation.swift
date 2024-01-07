extension WooAnalyticsEvent {
    enum ProductCreation {
        /// Event property keys.
        private enum Key {
            static let source = "source"
            static let storeHasProducts = "has_products"
            static let productType = "product_type"
            static let isVirtual = "is_virtual"
            static let creationType = "creation_type"
        }

        /// Tracked when the user taps to start adding a product.
        /// - Parameters:
        ///   - source: Entry point to product creation.
        ///   - storeHasProducts: Whether the store has any products when adding a product.
        static func addProductStarted(source: AddProductCoordinator.Source, storeHasProducts: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addProductStarted,
                              properties: [Key.source: source.analyticsValue,
                                           Key.storeHasProducts: storeHasProducts])
        }

        /// Tracked when the user selects a product type during the product creation flow.
        /// - Parameters:
        ///   - bottomSheetProductType: User selected product type from the bottom sheet.
        ///   - creationType: Product creation type.
        static func addProductTypeSelected(bottomSheetProductType: BottomSheetProductType, creationType: ProductCreationType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addProductTypeSelected,
                              properties: [Key.productType: bottomSheetProductType.productType.rawValue,
                                           Key.isVirtual: bottomSheetProductType.isVirtual,
                                           Key.creationType: creationType.analyticsType.rawValue])
        }
    }
}

extension AddProductCoordinator.Source {
    var analyticsValue: String {
        switch self {
            case .productsTab:
                return "products_tab"
            case .storeOnboarding:
                return "store_onboarding"
            case .productDescriptionAIAnnouncementModal:
                return "product_description_ai_announcement"
        }
    }
}

private extension ProductCreationType {
    var analyticsType: WooAnalyticsEvent.ProductsOnboarding.CreationType {
        switch self {
        case .template:
            return .template
        case .manual:
            return .manual
        }
    }
}
