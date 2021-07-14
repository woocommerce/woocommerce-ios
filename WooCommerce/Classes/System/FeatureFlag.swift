/// FeatureFlag exposes a series of features to be conditionally enabled on different builds.
///
enum FeatureFlag: Int {

    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null

    /// Barcode scanner for product inventory management
    ///
    case barcodeScanner

    /// Large titles on the main tabs
    ///
    case largeTitles

    /// Product Reviews
    ///
    case reviews

    /// Shipping labels - Milestones 2 & 3
    ///
    case shippingLabelsM2M3

    /// Shipping labels - Milestone 4
    ///
    case shippingLabelsM4

    /// Product AddOns first iteration
    ///
    case addOnsI1

    /// Site Plugin list entry point on Settings screen
    ///
    case sitePlugins

    /// Automatically Reconnect to a Known Card Reader
    ///
    case cardPresentKnownReader

    /// Card-Present Payments Onboarding
    ///
    case cardPresentOnboarding
}
