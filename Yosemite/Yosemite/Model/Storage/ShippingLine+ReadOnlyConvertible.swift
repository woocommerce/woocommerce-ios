import Foundation
import Storage


// MARK: - Storage.ShippingLine: ReadOnlyConvertible
//
extension Storage.ShippingLine: ReadOnlyConvertible {

    /// Updates the Storage.ShippingLine with the ReadOnly.
    ///
    public func update(with shippingLine: Yosemite.ShippingLine) {
        shippingId = Int64(shippingLine.shippingId)
        methodTitle = shippingLine.methodTitle
        methodId = shippingLine.methodId
        total = shippingLine.total
        totalTax = shippingLine.totalTax
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShippingLine {
        return ShippingLine(shippingId: Int(shippingId),
                            methodTitle: methodTitle ?? "",
                            methodId: methodId ?? "",
                            total: total ?? "",
                            totalTax: totalTax ?? "")
    }
}
