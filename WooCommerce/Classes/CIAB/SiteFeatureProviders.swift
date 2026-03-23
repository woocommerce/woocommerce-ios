/// Container for all site-type-resolved providers.
///
/// This is a plain struct (not a protocol) — a data bag, not an abstraction.
/// Consumers should receive individual providers via constructor injection
/// or key path subscriptions — not the entire struct.
///
struct SiteFeatureProviders {
    let dashboardCards: DashboardCardProviding
    let creatableProductTypes: CreatableProductTypeProviding
    let filterableProductTypes: FilterableProductTypeProviding
    let orderStatusEditing: OrderStatusEditingProviding
    let shipmentSplitting: ShipmentSplittingProviding
    let productRouting: ProductRoutingProviding
}
