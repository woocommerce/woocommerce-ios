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

    /// Returns a boolean indicating if the feature is enabled
    ///
    var enabled: Bool {
        switch self {
        case .stats:
            return BuildConfiguration.current == .localDeveloper
        case .reviews:
            return true
        case .refunds:
            return BuildConfiguration.current == .localDeveloper
        default:
            return true
        }
    }
}
