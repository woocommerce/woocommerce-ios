import Foundation
import WooFoundation
import protocol Storage.StorageManagerType

/// Extension helpers for `Order` related with Card Present Payments
///
 extension Order {
    private var currencyFormatter: CurrencyFormatter {
        CurrencyFormatter(currencySettings: CurrencySettings())
    }

    /// Determines whether this order can be paid with card
    ///
    /// - Parameters:
    ///     - cardPresentPaymentsConfiguration: The current configuration for the card payment. Use to check the validity of the order currency.
    ///     - products: A list of products linked to the store. Used to check whether the order contains any product of type subscription.
    ///
    func isEligibleForCardPresentPayment(cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration,
                                         products: [Product]) -> Bool {
        cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: cardPresentPaymentsConfiguration, products: products) == .eligible
    }

    func cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration,
                                       products: [Product]) -> OrderCardPresentPaymentEligibility {
        guard cardPresentPaymentsConfiguration.isSupportedCountry,
              isAmountEligibleForCardPayment,
              isStatusEligibleForCardPayment,
              isPaymentMethodEligibleForCardPayment,
              !containsAnySubscription(from: products),
              let orderCurrency = CurrencyCode(caseInsensitiveRawValue: currency) else {
            return .ineligible
        }
        guard cardPresentPaymentsConfiguration.currencies.contains(orderCurrency) else {
            return .unsupportedCurrency(orderCurrency.rawValue)
        }
        return .eligible
    }


    private var isAmountEligibleForCardPayment: Bool {
        // If the order is paid, it is not eligible.
        guard datePaid == nil else {
            return false
        }

        guard let totalAmount = currencyFormatter.convertToDecimal(total), totalAmount.decimalValue > 0 else {
            return false
        }

        // If there is a discrepancy between the orderTotal and the remaining amount to collect, it is not eligible
        // This is a temporary solution that will exclude, for example:
        // * orders that have been partially refunded.
        // * orders where the merchant has applied a discount manually
        // * in general, all orders where we might want to capture a payment for less than the total order amount
        let hasBeenPartiallyCharged = totalValue != netAmount
        return !hasBeenPartiallyCharged
    }


    private var isStatusEligibleForCardPayment: Bool {
        (status == .pending || status == .onHold || status == .processing || status == .failed)
    }

    private var isPaymentMethodEligibleForCardPayment: Bool {
        let paymentMethod = OrderPaymentMethod(rawValue: paymentMethodID)
        switch paymentMethod {
        case .booking, .cod, .woocommercePayments, .stripe, .none:
            return true
        case .unknown:
            return false
        }
    }

    private func containsAnySubscription(from products: [Product]) -> Bool {
        products.contains { $0.productType == .subscription }
    }
}
