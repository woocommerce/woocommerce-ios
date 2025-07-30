import Foundation
import Storage


// MARK: - Storage.ShippingMethod: ReadOnlyConvertible
//
extension Storage.ShippingMethod: ReadOnlyConvertible {

    /// Updates the Storage.ShippingMethod with the ReadOnly.
    ///
    public func update(with shippingMethod: Yosemite.ShippingMethod) {
        siteID = shippingMethod.siteID
        methodID = shippingMethod.methodID
        title = shippingMethod.title
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShippingMethod {
        return ShippingMethod(siteID: siteID,
                              methodID: methodID ?? "",
                              title: title ?? "")
    }
}
