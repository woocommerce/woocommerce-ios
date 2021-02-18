/// FeatureFlag exposes a series of features to be conditionally enabled on different builds.
///
enum FeatureFlag: Int {

    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null

    /// Barcode scanner for product inventory management
    ///
    case barcodeScanner

    /// Add Product Variations
    ///
    case addProductVariations

    /// Card Present Payments
    ///
    case cardPresentPayments

    /// Product Reviews
    ///
    case reviews

    /// Shipping labels - release 2
    ///
    case shippingLabelsRelease2
}
