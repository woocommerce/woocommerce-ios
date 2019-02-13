import Foundation
import Yosemite


// MARK: - OrderItem ViewModel
//
struct OrderItemViewModel {

    /// Yosemite.OrderItem
    ///
    let item: OrderItem

    /// Yosemite.Order.currency
    ///
    let currency: String

    /// Item's Name
    ///
    var name: String {
        return item.name
    }

    /// Currency Formatter
    ///
    let currencyFormatter: CurrencyFormatter

    /// Item's Quantity
    ///
    var quantity: String {
        return item.quantity.description
    }

    /// Item's Price
    /// Always return a string, even for zero amounts.
    ///
    var price: String {
        guard item.quantity.doubleValue > 1 else {
            return currencyFormatter.formatAmount(item.total, with: currency) ?? String()
        }

        let itemTotal = currencyFormatter.formatAmount(item.total, with: currency) ?? String()
        let itemSubtotal = currencyFormatter.formatAmount(item.price, with: currency) ?? String()

        return itemTotal + " (" + itemSubtotal + " × " + quantity + ")"
    }

    /// Item's Tax
    /// Return $0.00 if there is no tax.
    ///
    var tax: String? {
        let prefix = NSLocalizedString("Tax:", comment: "Tax label for total taxes line")
        let totalTax = currencyFormatter.formatAmount(item.totalTax, with: currency) ?? String()
        return prefix + " " + totalTax
    }

    /// Item's SKU
    ///
    var sku: String? {
        guard let sku = item.sku, sku.isEmpty == false else {
            return nil
        }

        let prefix = NSLocalizedString("SKU:", comment: "SKU label")
        return prefix + " " + sku
    }

    init(item: OrderItem, currency: String, formatter: CurrencyFormatter = CurrencyFormatter()) {
        self.item = item
        self.currency = currency
        self.currencyFormatter = formatter
    }
}
