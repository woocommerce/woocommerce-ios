import Foundation
import Yosemite
import protocol Storage.StorageManagerType

extension Order {
    func isEligibleForCardPresentPayment(cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration,
                                         products: [Product]) -> Bool {
        isAmountEligibleForCardPayment &&
        isStatusEligibleForCardPayment &&
        isPaymentMethodEligibleForCardPayment &&
        isCurrencyEligibleForCardPayment(cardPresentPaymentsConfiguration: cardPresentPaymentsConfiguration) &&
        !containsAnySubscription(from: products)
    }

    private var isAmountEligibleForCardPayment: Bool {
        // If the order is paid, it is not eligible.
        guard datePaid == nil else {
            return false
        }

        let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
        guard let totalAmount = currencyFormatter.convertToDecimal(from: total), totalAmount.decimalValue > 0 else {
            return false
        }

        // If there is a discrepancy between the orderTotal and the remaining amount to collect, it is not eligible
        // This is a temporary solution that will exclude, for example:
        // * orders that have been partially refunded.
        // * orders where the merchant has applied a discount manually
        // * in general, all orders where we might want to capture a payment for less than the total order amount
        let paymentViewModel = OrderPaymentDetailsViewModel(order: self)
        return !paymentViewModel.hasBeenPartiallyCharged
    }

    private var isStatusEligibleForCardPayment: Bool {
        (status == .pending || status == .onHold || status == .processing)
    }

    private var isPaymentMethodEligibleForCardPayment: Bool {
        let paymentMethod = OrderPaymentMethod(rawValue: paymentMethodID)
        switch paymentMethod {
        case .booking, .cod, .woocommercePayments, .none:
            return true
        case .unknown:
            return false
        }
    }

    private func isCurrencyEligibleForCardPayment(cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration) -> Bool {
        guard let currency = CurrencyCode(caseInsensitiveRawValue: currency) else {
            return false
        }
        return cardPresentPaymentsConfiguration.currencies.contains(currency)
    }

    func hasCardPresentEligiblePaymentGatewayAccount(from accounts: [PaymentGatewayAccount]) -> Bool {
        accounts.contains(where: \.isCardPresentEligible)
    }

    private func containsAnySubscription(from products: [Product]) -> Bool {
        items.contains { item in
            let product = products.filter({ item.productID == $0.productID }).first
            return product?.productType == .subscription
        }
    }
}
