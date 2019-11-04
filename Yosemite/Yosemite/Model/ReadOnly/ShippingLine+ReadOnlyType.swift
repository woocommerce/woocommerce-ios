import Foundation
import Storage


// MARK: - Yosemite.ShippingLine: ReadOnlyType
//
extension Yosemite.ShippingLine: ReadOnlyType {

    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of shippingLine: Any) -> Bool {
        guard let shippingLine = shippingLine as? Storage.ShippingLine else {
            return false
        }

        return shippingId == Int(shippingLine.shippingId)
    }
}
