/// FeatureFlag exposes a series of features to be conditionally enabled on different builds.
///
enum FeatureFlag: Int {

    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null

    /// Barcode scanner for product inventory management
    ///
    case barcodeScanner

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

    /// To be used for the In-app Feedback tasks until all tasks are completed.
    ///
    /// - SeeAlso: https://github.com/woocommerce/woocommerce-ios/projects/18
    ///
    case inAppFeedback
}
