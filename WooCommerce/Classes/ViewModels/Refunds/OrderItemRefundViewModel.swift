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
        let positiveTotal = item.total.replacingOccurrences(of: "-", with: "")

        guard abs(item.quantity) > 1 else {
            return currencyFormatter.formatAmount(positiveTotal, with: currency) ?? String()
        }


        let itemTotal = currencyFormatter.formatAmount(positiveTotal, with: currency) ?? String()
        let itemSubtotal = currencyFormatter.formatAmount(item.price, with: currency) ?? String()

        let priceTemplate = NSLocalizedString("%@ (%@ x %@)",
                                              comment: "<item total> (<item individual price> multipled by <quantity>)")
        let priceText = String.localizedStringWithFormat(priceTemplate, itemTotal, itemSubtotal, quantity)

        return priceText
    }

    /// Item's Tax
    /// Return $0.00 if there is no tax.
    ///
    var tax: String? {
        let totalTax = currencyFormatter.formatAmount(item.totalTax, with: currency) ?? String()
        let taxTemplate = NSLocalizedString("Tax: %@",
                                            comment: "Tax label for total taxes line, followed by the tax amount.")
        let taxText = String.localizedStringWithFormat(taxTemplate, totalTax)

        return taxText
    }

    /// Item's SKU
    ///
    var sku: String? {
        guard let sku = item.sku, sku.isEmpty == false else {
            return nil
        }

        let skuTemplate = NSLocalizedString("SKU: %@", comment: "SKU label, followed by the SKU")
        let skuText = String.localizedStringWithFormat(skuTemplate, sku)

        return skuText
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

    init(item: OrderItemRefund,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(),
         product: Product? = nil) {
        self.item = item
        self.currency = currency
        self.currencyFormatter = formatter
        self.product = product
    }
}
