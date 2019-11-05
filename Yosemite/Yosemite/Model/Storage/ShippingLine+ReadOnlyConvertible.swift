import Foundation
import Storage


// MARK: - Storage.ShippingLine: ReadOnlyConvertible
//
extension Storage.ShippingLine: ReadOnlyConvertible {

    /// Updates the Storage.ShippingLine with the ReadOnly.
    ///
    public func update(with shippingLine: Yosemite.ShippingLine) {
        shippingID = Int64(shippingLine.shippingID)
        methodTitle = shippingLine.methodTitle
        methodID = shippingLine.methodID
        total = shippingLine.total
        totalTax = shippingLine.totalTax
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShippingLine {
        return ShippingLine(shippingID: Int(shippingID),
                            methodTitle: methodTitle ?? "",
                            methodID: methodID ?? "",
                            total: total ?? "",
                            totalTax: totalTax ?? "")
    }
}
