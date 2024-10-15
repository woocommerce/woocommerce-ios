import Yosemite
import WooFoundation

/// Represents a shipping line in the Woo Shipping label creation flow.
struct WooShipping_ShippingLineViewModel: Identifiable {
    /// Unique ID for the shipping line.
    let id: Int64

    /// Title for the shipping line.
    let title: String

    /// Formatted total amount for the shipping line.
    let formattedTotal: String

    init(shippingLine: ShippingLine,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        id = shippingLine.shippingID
        title = shippingLine.methodTitle
        formattedTotal = currencyFormatter.formatAmount(shippingLine.total) ?? shippingLine.total
    }
}
