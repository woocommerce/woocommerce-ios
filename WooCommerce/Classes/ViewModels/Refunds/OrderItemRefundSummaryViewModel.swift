import Foundation
import Yosemite


// MARK: - OrderItemRefundSummary View Model
//
struct OrderItemRefundSummaryViewModel {

    /// Yosemite.OrderItemRefundSummary
    ///
    let item: OrderItemRefundSummary

    /// Yosemite.Product?
    ///
    var product: Product?

    /// Yosemite.Order.currency
    ///
    let currencyCode: String

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

    /// Item's Total
    ///
    var total: String {
        let positiveTotal = item.total.abs()
        return currencyFormatter.formatAmount(positiveTotal, with: currencyCode) ?? String()
    }

    /// Item's Price Summary
    /// Example: $140 ($35 x 4)
    /// Always return a string, even for zero amounts.
    ///
    var price: String {
        let itemPrice = currencyFormatter.formatAmount(item.price, with: currencyCode) ?? String()

        let priceTemplate = NSLocalizedString("%@ (%@ x %@)",
                                              comment: "<item total> (<item individual price> multipled by <quantity>)")
        let priceText = String.localizedStringWithFormat(priceTemplate, total, itemPrice, quantity)

        return priceText
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

    /// Designated initializer
    ///
    init(item: OrderItemRefundSummary,
         currencyCode: String,
         formatter: CurrencyFormatter = CurrencyFormatter(),
         product: Product? = nil) {
        self.item = item
        self.currencyCode = currencyCode
        self.currencyFormatter = formatter
        self.product = product
    }
}
