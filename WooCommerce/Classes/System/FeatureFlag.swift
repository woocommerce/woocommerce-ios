/// FeatureFlag exposes a series of features to be conditionally enabled on different builds.
///
enum FeatureFlag: Int {

    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null

    /// Barcode scanner for product inventory management
    ///
    case barcodeScanner

    /// Edit products - release 3
    ///
    case editProductsRelease3

    /// Edit products - release 4
    ///
    case editProductsRelease4

    /// Edit products - release 5
    ///
    case editProductsRelease5

    /// Product Reviews
    ///
    case reviews

    /// Refunds
    ///
    case issueRefunds
}
