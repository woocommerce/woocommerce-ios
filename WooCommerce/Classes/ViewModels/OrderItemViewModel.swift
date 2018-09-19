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
    var money: MoneyFormatter

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
            return money.format(value: item.total, currencyCode: currency)
        }

        let itemTotal = money.format(value: item.total, currencyCode: currency)
        let itemSubtotal = money.format(value: item.subtotal, currencyCode: currency)

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
        let totalTax = money.format(value: item.totalTax, currencyCode: currency)
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
        self.money = money
    }
}
