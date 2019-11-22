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

    /// Store stats
    ///
    case stats

    /// Product Reviews
    ///
    case reviews

    /// Refunds
    ///
    case refunds
}
