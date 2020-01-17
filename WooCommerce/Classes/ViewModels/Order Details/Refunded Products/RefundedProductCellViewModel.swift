import Foundation
import Yosemite


// MARK: - View Model for a refunded product cell
//
struct RefundedProductCellViewModel {

    /// RefundedProduct
    ///
    let refundedProduct: RefundedProduct

    /// Yosemite.Order.currency
    ///
    let currency: String

    /// Yosemite.Product
    ///
    let product: Product?

    /// Refunded Product Name
    ///
    var name: String {
        return refundedProduct.name
    }

    /// Currency Formatter
    ///
    let currencyFormatter: CurrencyFormatter

    /// Refunded Product Quantity
    ///
    var quantity: String {
        return abs(refundedProduct.quantity).description
    }

    /// Refunded Product Price
    /// Always return a string, even for zero amounts.
    ///
    var price: String {
        guard abs(refundedProduct.quantity) > 1 else {
            let positiveTotal = refundedProduct.total.abs()
            return currencyFormatter.formatAmount(positiveTotal, with: currency) ?? String()
        }

        let positiveTotal = refundedProduct.total.abs()
        let itemTotal = currencyFormatter.formatAmount(positiveTotal, with: currency) ?? String()
        let itemSubtotal = currencyFormatter.formatAmount(refundedProduct.price, with: currency) ?? String()

        let priceTemplate = NSLocalizedString("%@ (%@ x %@)",
                                              comment: "<item total> (<item individual price> multipled by <quantity>)")
        let priceText = String.localizedStringWithFormat(priceTemplate, itemTotal, itemSubtotal, quantity)

        return priceText
    }

    /// Item's SKU
    ///
    var sku: String? {
        guard let sku = refundedProduct.sku, sku.isEmpty == false else {
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

    init(refundedProduct: RefundedProduct,
         currency: String,
         formatter: CurrencyFormatter = CurrencyFormatter(),
         product: Product? = nil) {
        self.refundedProduct = refundedProduct
        self.currency = currency
        self.currencyFormatter = formatter
        self.product = product
    }
}
