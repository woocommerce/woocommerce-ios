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

    /// Money Formatter
    ///
    let moneyFormatter: MoneyFormatter

    /// Item's Quantity
    ///
    var quantity: String {
        return item.quantity.description
    }

    /// Item's Price
    /// Always return a string, even for zero amounts.
    ///
    var price: String {
        guard item.quantity > 1 else {
            return moneyFormatter.format(value: item.total, currencyCode: currency) ?? String()
        }

        let itemTotal = moneyFormatter.format(value: item.total, currencyCode: currency) ?? String()
        let itemSubtotal = moneyFormatter.format(value: item.subtotal, currencyCode: currency) ?? String()

        return itemTotal + " (" + itemSubtotal + " × " + quantity + ")"
    }

    /// Item's Tax
    /// Not all items have a tax. Return nil if amount is zero, so labels will hide.
    ///
    var tax: String? {
        guard item.totalTax.isEmpty == false else {
            return nil
        }

        let prefix = NSLocalizedString("Tax:", comment: "Tax label for total taxes line")
        let totalTax = moneyFormatter.format(value: item.totalTax, currencyCode: currency) ?? String()
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

    init(item: OrderItem, currency: String, money: MoneyFormatter = MoneyFormatter()) {
        self.item = item
        self.currency = currency
        self.moneyFormatter = money
    }
}
