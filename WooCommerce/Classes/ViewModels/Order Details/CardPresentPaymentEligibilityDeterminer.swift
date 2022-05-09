
import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class CardPresentPaymentEligibilityDeterminer {
    private let storageManager: StorageManagerType
    private let order: Order
    /// IPP Configuration
    private let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration
    private lazy var currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    init(order: Order,
         cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.order = order
        self.cardPresentPaymentsConfiguration = cardPresentPaymentsConfiguration
        self.storageManager = storageManager
    }

    func isEligibleForCardPresentPayment(order: Order,
                                         accounts: [PaymentGatewayAccount],
                                         products: [Product]) -> Bool {
            isOrderAmountEligibleForCardPayment() &&
            isOrderCurrencyEligibleForCardPayment() &&
            isOrderStatusEligibleForCardPayment() &&
            isOrderPaymentMethodEligibleForCardPayment() &&
            hasCardPresentEligiblePaymentGatewayAccount(from: accounts) &&
        !orderContainsAnySubscription(from: products)
    }

    private func isOrderAmountEligibleForCardPayment() -> Bool {
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

    private func isOrderCurrencyEligibleForCardPayment() -> Bool {
        guard let currency = CurrencyCode(caseInsensitiveRawValue: order.currency) else {
            return false
        }
        return cardPresentPaymentsConfiguration.currencies.contains(currency)
    }

    private func isOrderStatusEligibleForCardPayment() -> Bool {
        (order.status == .pending || order.status == .onHold || order.status == .processing)
    }

    private func isOrderPaymentMethodEligibleForCardPayment() -> Bool {
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

    private func orderContainsAnySubscription(from products: [Product]) -> Bool {
        order.items.contains { item in
            let product = products.filter({ item.productID == $0.productID }).first
            return product?.productType == .subscription
        }
    }
}
