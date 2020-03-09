import Foundation
import Storage


// MARK: - Storage.OrderCount: ReadOnlyConvertible
//
extension Storage.OrderCount: ReadOnlyConvertible {

    /// Updates the Storage.OrderCount with the ReadOnly.
    ///
    public func update(with orderCount: Yosemite.OrderCount) {
        siteID = orderCount.siteID
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderCount {
        let orderCountItems = items?.map { $0.toReadOnly() } ?? [Yosemite.OrderCountItem]()

        return OrderCount(siteID: siteID,
                          items: orderCountItems)
    }
}
