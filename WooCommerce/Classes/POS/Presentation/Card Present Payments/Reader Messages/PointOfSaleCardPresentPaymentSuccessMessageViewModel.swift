import Foundation
import struct Yosemite.Order
import class WooFoundation.CurrencyFormatter

struct PointOfSaleCardPresentPaymentSuccessMessageViewModel {
    let title: String = Localization.title
    var message: String? = nil

    private var order: Order? = nil
    private let currencyFormatter: CurrencyFormatter

    init(currencyFormatter: CurrencyFormatter = .init(currencySettings: ServiceLocator.currencySettings)) {
        self.currencyFormatter = currencyFormatter
    }

    func withOrder(_ order: Order?) -> PointOfSaleCardPresentPaymentSuccessMessageViewModel {
        guard let order = order,
              let total = currencyFormatter.formatAmount(order.total, with: order.currency) else {
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
