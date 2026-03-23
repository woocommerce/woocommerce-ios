import Yosemite

/// Filterable product types for standard (non-CIAB) sites.
///
/// Shows all standard product types. Plugin-gated types (subscriptions, bundles,
/// composites) are included with availability and promo URLs based on active plugins.
/// Active plugins are passed in at construction time by the factory.
///
struct StandardFilterableProductTypeProvider: FilterableProductTypeProviding {
    private let activePlugins: [Plugin]

    init(activePlugins: [Plugin]) {
        self.activePlugins = activePlugins
    }

    var filterableProductTypes: [PromotableProductType] {
        let isSubscriptionsAvailable = activePlugins.contains(.wooSubscriptions)
        let isCompositeProductsAvailable = activePlugins.contains(.wooCompositeProducts)
        let isProductBundlesAvailable = activePlugins.contains(.wooProductBundles)

        return [
            .init(productType: .simple, isAvailable: true, promoteUrl: nil),
            .init(productType: .variable, isAvailable: true, promoteUrl: nil),
            .init(productType: .grouped, isAvailable: true, promoteUrl: nil),
            .init(productType: .affiliate, isAvailable: true, promoteUrl: nil),
            .init(productType: .subscription,
                  isAvailable: isSubscriptionsAvailable,
                  promoteUrl: WooConstants.URLs.subscriptionsExtension.asURL()),
            .init(productType: .variableSubscription,
                  isAvailable: isSubscriptionsAvailable,
                  promoteUrl: WooConstants.URLs.subscriptionsExtension.asURL()),
            .init(productType: .bundle,
                  isAvailable: isProductBundlesAvailable,
                  promoteUrl: WooConstants.URLs.productBundlesExtension.asURL()),
            .init(productType: .composite,
                  isAvailable: isCompositeProductsAvailable,
                  promoteUrl: WooConstants.URLs.compositeProductsExtension.asURL()),
        ]
    }
}

/// Filterable product types for CIAB sites.
///
/// Only simple, affiliate, and booking products are shown.
///
struct CIABFilterableProductTypeProvider: FilterableProductTypeProviding {
    var filterableProductTypes: [PromotableProductType] {
        [
            .init(productType: .simple, isAvailable: true, promoteUrl: nil),
            .init(productType: .booking, isAvailable: true, promoteUrl: nil),
            .init(productType: .affiliate, isAvailable: true, promoteUrl: nil),
        ]
    }
}
