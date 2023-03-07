import Foundation
import Storage

// MARK: - Storage.OrderTaxLine: ReadOnlyConvertible
//
extension Storage.OrderTaxLine: ReadOnlyConvertible {

    /// Updates the `Storage.OrderTaxLine` using the ReadOnly representation (`Networking.OrderTaxLine`)
    ///
    /// - Parameter taxLine: ReadOnly representation of OrderTaxLine
    ///
    public func update(with taxLine: Yosemite.OrderTaxLine) {
        taxID = taxLine.taxID
        rateCode = taxLine.rateCode
        rateID = taxLine.rateID
        label = taxLine.label
        isCompoundTaxRate = taxLine.isCompoundTaxRate
        totalTax = taxLine.totalTax
        totalShippingTax = taxLine.totalShippingTax
        ratePercent = taxLine.ratePercent
    }

    /// Returns a ReadOnly (`Networking.OrderTaxLine`) version of the `Storage.OrderTaxLine`
    ///
    public func toReadOnly() -> Yosemite.OrderTaxLine {
        let taxAttributes = attributes?.map { $0.toReadOnly() } ?? [Yosemite.OrderItemAttribute]()

        return OrderTaxLine(taxID: taxID,
                            rateCode: rateCode ?? "",
                            rateID: rateID,
                            label: label ?? "",
                            isCompoundTaxRate: isCompoundTaxRate,
                            totalTax: totalTax ?? "",
                            totalShippingTax: totalShippingTax ?? "",
                            ratePercent: ratePercent,
                            attributes: taxAttributes)
    }
}
