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
    func cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration,
                                       products: [Product]) -> OrderCardPresentPaymentEligibility {
        guard cardPresentPaymentsConfiguration.isSupportedCountry else {
            DDLogInfo("[Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=country_not_supported " +
                      "country=\(cardPresentPaymentsConfiguration.countryCode)")
            return .ineligible
        }
        guard isAmountEligibleForCardPayment else {
            return .ineligible
        }
        guard isStatusEligibleForCardPayment else {
            DDLogInfo("[Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=order_status_not_supported")
            return .ineligible
        }
        guard isPaymentMethodEligibleForCardPayment else {
            DDLogInfo("[Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=payment_method_not_supported")
            return .ineligible
        }
        guard !containsAnySubscription(from: products) else {
            DDLogInfo("[Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=subscription")
            return .ineligible
        }
        guard let orderCurrency = CurrencyCode(caseInsensitiveRawValue: currency) else {
            DDLogWarn("[Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=currency_unrecognized")
            return .ineligible
        }
        guard cardPresentPaymentsConfiguration.currencies.contains(orderCurrency) else {
            DDLogInfo("[Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=currency_not_supported " +
                      "country=\(cardPresentPaymentsConfiguration.countryCode.rawValue) currency=\(orderCurrency.rawValue)")
            return .unsupportedCurrency(orderCurrency.rawValue)
        }
        return .eligible
    }


    private var isAmountEligibleForCardPayment: Bool {
        // If the order is paid, it is not eligible.
        guard datePaid == nil else {
            DDLogInfo("[Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=order_already_paid")
            return false
        }

        guard let totalAmount = currencyFormatter.convertToDecimal(total) else {
            DDLogWarn("[Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=invalid_total")
            return false
        }
        guard totalAmount.decimalValue > 0 else {
            DDLogInfo("[Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=non_positive_total")
            return false
        }

        // If there is a discrepancy between the orderTotal and the remaining amount to collect, it is not eligible
        // This is a temporary solution that will exclude, for example:
        // * orders that have been partially refunded.
        // * orders where the merchant has applied a discount manually
        // * in general, all orders where we might want to capture a payment for less than the total order amount
        let hasBeenPartiallyCharged = totalValue != netAmount
        if hasBeenPartiallyCharged {
            DDLogInfo("[Card payment eligibility] siteID=\(siteID) orderID=\(orderID) reason=remaining_amount_mismatch")
        }
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
