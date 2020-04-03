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

    /// Edit products - release 3
    ///
    case editProductsRelease3

    /// Readonly Product variants
    ///
    case readonlyProductVariants

    /// Product Reviews
    ///
    case reviews

    /// Refunds
    ///
    case refunds
}
