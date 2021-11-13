import Foundation

/// A structure to hold the basic details for a selected package on Package Details screen of Shipping Label purchase flow.
///
struct ShippingLabelPackageAttributes: Equatable {

    /// Default box ID for boxes shipping in original packaging.
    static let originalPackagingBoxID = "individual"

    /// Unique ID of the package.
    let id: String = UUID().uuidString

    /// Name of the package.
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

    /// Returns an item in the package that contains product or variation with the specified ID,
    /// and the rest of the items in the package. If the item has quantity great than one,
    /// the rest of the items will contain an item with the same `productOrVariationID` but with reduced quantity.
    ///
    func partitionItems(using productOrVariationID: Int64) -> (matchingItem: ShippingLabelPackageItem?, rest: [ShippingLabelPackageItem]) {
        var matchingItem: ShippingLabelPackageItem?
        var updatedItems: [ShippingLabelPackageItem] = []
        for item in items {
            if item.productOrVariationID == productOrVariationID, matchingItem == nil {
                // If found an item with matching product or variation ID,
                // create a copy of the item with quantity = 1.
                matchingItem = ShippingLabelPackageItem(copy: item, quantity: 1)

                // If the item has quantity > 1, create a copy of the item with the reduced quantity and append to the list.
                if item.quantity > 1 {
                    let newItem = ShippingLabelPackageItem(copy: item, quantity: item.quantity - 1)
                    updatedItems.append(newItem)
                }
            } else {
                updatedItems.append(item)
            }
        }
        return (matchingItem: matchingItem, rest: updatedItems)
    }
}
