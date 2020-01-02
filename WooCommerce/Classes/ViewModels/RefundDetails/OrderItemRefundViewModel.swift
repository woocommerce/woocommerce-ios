import Foundation
import Yosemite


// MARK: - OrderItemRefund View Model
//
struct OrderItemRefundViewModel {

    /// Yosemite.OrderItemRefund
    ///
    let item: OrderItemRefund

    /// Yosemite.Order.currency
    ///
    let currency: String

    /// Yosemite.Product
    ///
    let product: Product?

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
        return abs(item.quantity).description
    }

    /// Item's Price
    /// Always return a string, even for zero amounts.
    ///
    var price: String {
        guard abs(item.quantity) > 1 else {
            return currencyFormatter.formatAmount(item.total, with: currency) ?? String()
        }

        let positiveTotal = item.total.replacingOccurrences(of: "-", with: "")
        let itemTotal = currencyFormatter.formatAmount(positiveTotal, with: currency) ?? String()
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

    /// Grab the first available image for a product.
    ///
    var imageURL: URL? {
        guard let productImageURLString = product?.images.first?.src else {
            return nil
        }

        return URL(string: productImageURLString)
    }

    /// Check to see if the product has an image URL.
    ///
    var productHasImage: Bool {
        return imageURL != nil
    }

    init(item: OrderItemRefund, currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(),
         product: Product? = nil) {
        self.item = item
        self.currency = currency
        self.currencyFormatter = formatter
        self.product = product
    }
}
