import Foundation
import struct Yosemite.Order
import class WooFoundation.CurrencyFormatter

struct PointOfSaleCardPresentPaymentSuccessMessageViewModel {
    let title: String = Localization.title
    var message: String? = nil

    private var order: Order? = nil

    typealias FormatAmount = (_ amount: String, _ currency: String?, _ locale: Locale) -> String?
    private let formatAmount: FormatAmount

    init(formatAmount: @escaping FormatAmount = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatAmount) {
        self.formatAmount = formatAmount
    }

    func withOrder(_ order: Order?) -> PointOfSaleCardPresentPaymentSuccessMessageViewModel {
        guard let order = order,
              let total = formatAmount(order.total, order.currency, .current) else {
            return self
        }

        var viewModel  = self
        viewModel.message = String(format: Localization.message, total)
        return viewModel
    }
}

private extension PointOfSaleCardPresentPaymentSuccessMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.paymentSuccessful.title",
            value: "Payment successful!",
            comment: "Title shown to users when payment is made successfully."
        )

        static let message = NSLocalizedString(
            "pointOfSale.cardPresent.paymentSuccessful.message",
            value: "A payment of %1$@ was successfully made",
            comment: "Message shown to users when payment is made. %1$@ indicates a total sum, e.g $10.5"
        )
    }
}
