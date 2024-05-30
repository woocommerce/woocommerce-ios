import Foundation
import WooFoundation
import struct Yosemite.ShippingLine
import struct Yosemite.ShippingMethod

struct ShippingLineRowViewModel: Identifiable {
    /// Shipping line ID
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
    let onEditShippingLine: (Int64) -> Void

    init(id: Int64,
         shippingTitle: String,
         shippingMethod: String?,
         shippingAmount: String,
         editable: Bool,
         onEditShippingLine: @escaping (Int64) -> Void) {
        self.id = id
        self.shippingTitle = shippingTitle
        self.shippingMethod = shippingMethod
        self.shippingAmount = shippingAmount
        self.editable = editable
        self.onEditShippingLine = onEditShippingLine
    }

    init(shippingLine: ShippingLine,
         shippingMethods: [ShippingMethod],
         editable: Bool,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         onEditShippingLine: @escaping (Int64) -> Void = { _ in }) {
        let formattedAmount = currencyFormatter.formatAmount(shippingLine.total) ?? shippingLine.total
        let shippingMethod = shippingMethods.first(where: { $0.methodID == shippingLine.methodID })?.title

        self.init(id: shippingLine.shippingID,
                  shippingTitle: shippingLine.methodTitle,
                  shippingMethod: shippingMethod,
                  shippingAmount: formattedAmount,
                  editable: editable,
                  onEditShippingLine: onEditShippingLine)
    }

    /// Edit the shipping line
    ///
    func editShippingLine() {
        onEditShippingLine(id)
    }
}
