import Foundation

/// A structure to hold the basic details for a selected package on Package Details screen of Shipping Label purchase flow.
///
struct ShippingLabelPackageAttributes: Equatable {

    /// Default box ID for boxes shipping in original packaging.
    static let originalPackagingBoxID = "individual"

    /// ID of the selected package.
    let packageID: String

    /// Total weight of the package in string value.
    let totalWeight: String

    /// List of items in the package.
    let items: [ShippingLabelPackageItem]
}

extension ShippingLabelPackageAttributes {
    var isOriginalPackaging: Bool {
        packageID == Self.originalPackagingBoxID
    }
}
