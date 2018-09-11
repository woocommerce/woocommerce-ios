import Foundation
import Yosemite


// MARK: - OrderItem ViewModel
//
struct OrderItemViewModel {

    /// Yosemite.OrderItem
    ///
    let item: OrderItem

    /// Order's Currency Formatter
    ///
    let currencyFormatter: NumberFormatter


    /// Item's Name
    ///
    var name: String {
        return item.name
    }

    /// Item's Quantity
    ///
    var quantity: String {
        return item.quantity.description
    }

    /// Item's Price
    ///
    var price: String {
        let itemTotal = currencyFormatter.string(for: item.total) ?? ""
        guard item.quantity > 1 else {
            return itemTotal
        }

        let itemSubtotal = currencyFormatter.string(for: item.subtotal) ?? ""

        return itemTotal + " (" + itemSubtotal + " × " + quantity + ")"
    }

    /// Item's Tax
    ///
    var tax: String? {
        guard item.totalTax.isEmpty == false else {
            return nil
        }
        let totalTax = currencyFormatter.string(for: item.totalTax) ?? ""

        let prefix = NSLocalizedString("Tax:", comment: "Tax label for total taxes line")
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
}
