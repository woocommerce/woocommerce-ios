import Foundation
import Storage


// MARK: - Storage.OrderStatus: ReadOnlyConvertible
//
extension Storage.OrderStatus: ReadOnlyConvertible {

    /// Updates the Storage.OrderStatus with the ReadOnly.
    ///
    public func update(with orderStatus: Yosemite.OrderStatus) {
        name = orderStatus.name
        siteID = Int64(orderStatus.siteID)
        slug = orderStatus.slug
        total = Int64(orderStatus.total)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderStatus {
        return OrderStatus(name: name, siteID: Int64(siteID), slug: slug, total: Int(total))
    }
}
