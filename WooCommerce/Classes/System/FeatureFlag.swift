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

    /// Product Reviews
    ///
    case reviews

    /// Shipping labels - release 1
    ///
    case shippingLabelsRelease1
}
