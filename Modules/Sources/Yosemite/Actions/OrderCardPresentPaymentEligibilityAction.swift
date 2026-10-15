import Foundation

// Defines the actions supported by the OrderCardPresentPaymentEligibilityStore
public enum OrderCardPresentPaymentEligibilityAction: Action {
    case checkEligibility(orderID: Int64,
                          siteID: Int64,
                          cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration,
                          onCompletion: (Result<OrderCardPresentPaymentEligibility, Error>) -> Void)

    /// Checks whether the order was sold as a subscription, which makes it ineligible for card present payments.
    /// Unlike `checkEligibility`, this may hit the network. It completes with `true` when the order contains a subscription.
    /// A failure means the status couldn't be determined, and callers should treat the order as ineligible.
    case checkOrderContainsSubscription(orderID: Int64,
                                        siteID: Int64,
                                        onCompletion: (Result<Bool, Error>) -> Void)
}

/// A currency explanation is only relevant when the order passes the other payment checks.
public enum OrderCardPresentPaymentEligibility: Equatable {
    case eligible
    case unsupportedCurrency(String)
    case ineligible
}
