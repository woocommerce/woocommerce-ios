import Foundation
import Storage


// MARK: - Storage.TopEarnerStatsItem: ReadOnlyConvertible
//
extension Storage.TopEarnerStatsItem: ReadOnlyConvertible {

    /// Updates the Storage.TopEarnerStatsItem with the ReadOnly.
    ///
    public func update(with statsItem: Yosemite.TopEarnerStatsItem) {
        productID = Int64(statsItem.productID)
        productName = statsItem.productName
        quantity = Int64(statsItem.quantity)
        price = statsItem.price
        total = statsItem.total
        currency = statsItem.currency
        imageUrl = statsItem.imageUrl
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.TopEarnerStatsItem {
        return TopEarnerStatsItem(productID: Int64(productID),
                                  productName: productName ?? "",
                                  quantity: Int(quantity),
                                  price: price,
                                  total: total,
                                  currency: currency ?? "",
                                  imageUrl: imageUrl ?? "")
    }
}
