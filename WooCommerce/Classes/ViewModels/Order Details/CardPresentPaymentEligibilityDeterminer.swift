
import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class CardPresentPaymentEligibilityDeterminer {
    private lazy var currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    func isEligibleForCardPresentPayment(order: Order,
                                         cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration,
                                         products: [Product]) -> Bool {
        isOrderAmountEligibleForCardPayment(order) &&
        isOrderCurrencyEligibleForCardPayment(order, cardPresentPaymentsConfiguration: cardPresentPaymentsConfiguration) &&
        isOrderStatusEligibleForCardPayment(order) &&
        isOrderPaymentMethodEligibleForCardPayment(order) &&
        !orderContainsAnySubscription(from: products, order: order)
    }

    private func isOrderAmountEligibleForCardPayment(_ order: Order) -> Bool {
        // If the order is paid, it is not eligible.
        guard order.datePaid == nil else {
            return false
        }

        guard let totalAmount = currencyFormatter.convertToDecimal(from: order.total), totalAmount.decimalValue > 0 else {
            return false
        }

        // If there is a discrepancy between the orderTotal and the remaining amount to collect, it is not eligible
        // This is a temporary solution that will exclude, for example:
        // * orders that have been partially refunded.
        // * orders where the merchant has applied a discount manually
        // * in general, all orders where we might want to capture a payment for less than the total order amount
        let paymentViewModel = OrderPaymentDetailsViewModel(order: order)
        return !paymentViewModel.hasBeenPartiallyCharged
    }

    private func isOrderCurrencyEligibleForCardPayment(_ order: Order, cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration) -> Bool {
        guard let currency = CurrencyCode(caseInsensitiveRawValue: order.currency) else {
            return false
        }
        return cardPresentPaymentsConfiguration.currencies.contains(currency)
    }

    private func isOrderStatusEligibleForCardPayment(_ order: Order) -> Bool {
        (order.status == .pending || order.status == .onHold || order.status == .processing)
    }

    private func isOrderPaymentMethodEligibleForCardPayment(_ order: Order) -> Bool {
        let paymentMethod = OrderPaymentMethod(rawValue: order.paymentMethodID)
        switch paymentMethod {
        case .booking, .cod, .woocommercePayments, .none:
            return true
        case .unknown:
            return false
        }
    }

    func hasCardPresentEligiblePaymentGatewayAccount(from accounts: [PaymentGatewayAccount]) -> Bool {
        accounts.contains(where: \.isCardPresentEligible)
    }

    private func orderContainsAnySubscription(from products: [Product], order: Order) -> Bool {
        order.items.contains { item in
            let product = products.filter({ item.productID == $0.productID }).first
            return product?.productType == .subscription
        }
    }
}
