/// Provides the set of product types available for filtering on the current site.
///
/// Standard sites show all types with plugin-gated availability (subscriptions,
/// bundles, composites). CIAB sites show a reduced set (simple, affiliate, booking).
///
protocol FilterableProductTypeProviding {
    var filterableProductTypes: [PromotableProductType] { get }
}
