/// FeatureFlag exposes a series of features to be conditionally enabled on different builds.
///
enum FeatureFlag: Int {

    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null

    /// Product list
    ///
    case productList

    /// Edit products
    ///
    case editProducts

    /// Edit products - release 2
    ///
    case editProductsRelease2

    /// Readonly Product variants
    ///
    case readonlyProductVariants

    /// Store stats
    ///
    case stats

    /// Product Reviews
    ///
    case reviews

    /// Refunds
    ///
    case refunds

    /// Order List Redesign
    ///
    /// TODO: Remove when the redesign is complete. See https://github.com/woocommerce/woocommerce-ios/issues/956.
    ///
    case orderListRedesign
}
