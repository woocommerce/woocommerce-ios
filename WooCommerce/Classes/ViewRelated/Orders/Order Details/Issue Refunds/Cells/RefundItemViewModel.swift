import Foundation
import Yosemite

/// Represents an order item to be refunded. Meant to be rendered by `RefundItemTableViewCell`
///
struct RefundItemViewModel {
    let productImage: String?
    let productTitle: String
    let productQuantityAndPrice: String
    let quantityToRefund: String
}

// MARK: Convenience Initializers
extension RefundItemViewModel {

    /// Creates a `RefundItemViewModel` based on an `OrderItem`, it's related product and it's currency..
    /// `QuantityToRefund` is set to 0.
    ///
    init(item: OrderItem, product: Product?, refundQuantity: Int, currency: String, currencySettings: CurrencySettings) {
        productImage = product?.images.first?.src
        productTitle = item.name
        quantityToRefund = String(refundQuantity)
        productQuantityAndPrice = {
            let quantity = NumberFormatter.localizedString(from: item.quantity as NSDecimalNumber, number: .decimal)
            let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
            let price = currencyFormatter.formatAmount(item.price, with: currency) ?? ""
            return String(format: Localization.quantityAndPriceFormat, quantity, price)
        }()
    }
}

// MARK: Constant
private extension RefundItemViewModel {
    enum Localization {
        static let quantityAndPriceFormat = NSLocalizedString("%@ x %@ each", comment: "Refund item price and quantity format. EG: 2 x $10.00 each")
    }
}
