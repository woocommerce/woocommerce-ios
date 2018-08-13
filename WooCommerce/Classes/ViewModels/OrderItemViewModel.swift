import Foundation
import Yosemite


// MARK: - OrderItem ViewModel
//
struct OrderItemViewModel {

    /// Yosemite.OrderItem
    ///
    let item: OrderItem

    /// Order's Currency Symbol!
    ///
    let currencySymbol: String


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
        guard item.quantity > 1 else {
            return currencySymbol + " " + item.total
        }

        return currencySymbol + " "  + item.total + " (" + currencySymbol + item.subtotal + " × " + quantity + ")"
    }

    /// Item's Tax
    ///
    var tax: String? {
        guard item.totalTax.isEmpty == false else {
            return nil
        }

        let prefix = NSLocalizedString("Tax:", comment: "Tax label for total taxes line")
        return prefix + " " + currencySymbol + " " + item.totalTax
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
