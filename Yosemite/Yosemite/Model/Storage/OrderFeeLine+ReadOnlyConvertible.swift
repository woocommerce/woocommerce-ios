import Foundation
import Storage


// MARK: - Storage.OrderFeeLine: ReadOnlyConvertible
//
extension Storage.OrderFeeLine: ReadOnlyConvertible {

    /// Updates the Storage.OrderFeeLine with the ReadOnly.
    ///
    public func update(with feeLine: Yosemite.OrderFeeLine) {
        feeID = feeLine.feeID
        name = feeLine.name
        taxClass = feeLine.taxClass
        taxStatusKey = feeLine.taxStatus.rawValue
        total = feeLine.total
        totalTax = feeLine.totalTax
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderFeeLine {
        let feeTaxes = taxes?.map { $0.toReadOnly() } ?? [Yosemite.OrderItemTax]()
        let feeAttributes = attributes?.map { $0.toReadOnly() } ?? [Yosemite.OrderItemAttribute]()

        return OrderFeeLine(feeID: feeID,
                            name: name ?? "",
                            taxClass: taxClass ?? "",
                            taxStatus: OrderFeeTaxStatus(rawValue: taxStatusKey),
                            total: total ?? "",
                            totalTax: totalTax ?? "",
                            taxes: feeTaxes,
                            attributes: feeAttributes)
    }
}
