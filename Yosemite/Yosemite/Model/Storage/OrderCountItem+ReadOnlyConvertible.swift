import Foundation
import Storage


// MARK: - Storage.OrderCountItem: ReadOnlyConvertible
//
extension Storage.OrderCountItem: ReadOnlyConvertible {

    /// Updates the Storage.OrderCountItem with the ReadOnly.
    ///
    public func update(with orderCountItem: Yosemite.OrderCountItem) {
        slug = orderCountItem.slug
        name = orderCountItem.name
        total = Int64(orderCountItem.total)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderCountItem {
        return OrderCountItem(slug: slug ?? "",
                              name: name ?? "",
                              total: Int(total))
    }
}
