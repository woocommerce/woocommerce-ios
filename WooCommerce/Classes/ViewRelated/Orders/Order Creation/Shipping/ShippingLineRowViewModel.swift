import Foundation
import WooFoundation
import struct Yosemite.ShippingLine
import struct Yosemite.ShippingMethod

struct ShippingLineRowViewModel: Identifiable {
    /// ID for the row view model
    let id: Int64

    /// Title for the shipping line
    let shippingTitle: String

    /// Name of the shipping method for the shipping line
    let shippingMethod: String?

    /// Formatted amount for the shipping line
    let shippingAmount: String

    /// Whether the row can be edited
    let editable: Bool

    /// Closure to be invoked when the shipping line is edited
    let onEditShippingLine: () -> Void = {} // TODO-12581: Support editing shipping lines

    init(id: Int64,
         shippingTitle: String,
         shippingMethod: String?,
         shippingAmount: String,
         editable: Bool) {
        self.id = id
        self.shippingTitle = shippingTitle
        self.shippingMethod = shippingMethod
        self.shippingAmount = shippingAmount
        self.editable = editable
    }

    init(shippingLine: ShippingLine,
         shippingMethods: [ShippingMethod],
         editable: Bool,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        let formattedAmount = currencyFormatter.formatAmount(shippingLine.total) ?? shippingLine.total
        let shippingMethod = shippingMethods.first(where: { $0.methodID == shippingLine.methodID })?.title

        self.init(id: shippingLine.shippingID,
                  shippingTitle: shippingLine.methodTitle,
                  shippingMethod: shippingMethod,
                  shippingAmount: formattedAmount,
                  editable: editable)
    }
}
