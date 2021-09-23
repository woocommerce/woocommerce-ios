import Foundation

/// A structure to hold the basic details for a selected package on Package Details screen of Shipping Label purchase flow.
///
struct ShippingLabelPackageAttributes: Hashable, Equatable {

    /// Default box ID for original packages.
    static let originalPackagingBoxID = "individual"

    /// ID of the selected package.
    let packageID: String

    /// Total weight of the package in string value.
    let totalWeight: String

    /// List of product or variation IDs for items in the package.
    let productIDs: [Int64]

    /// Length of the package, required if the package is original packaging.
    let length: Double?

    /// Width of the package, required if the package is original packaging.
    let width: Double?

    /// Height of the package, required if the package is original packaging.
    let height: Double?

    init(packageID: String, totalWeight: String, productIDs: [Int64], length: Double? = nil, width: Double? = nil, height: Double? = nil) {
        self.packageID = packageID
        self.totalWeight = totalWeight
        self.productIDs = productIDs
        self.length = length
        self.width = width
        self.height = height
    }
}
