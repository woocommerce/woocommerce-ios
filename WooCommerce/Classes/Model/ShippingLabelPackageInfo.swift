import Foundation

/// A structure to hold the basic details for a selected package on Package Details screen of Shipping Label purchase flow.
///
struct ShippingLabelPackageInfo: Hashable {
    let packageID: String
    let totalWeight: String
    let productIDs: [Int64]
}
