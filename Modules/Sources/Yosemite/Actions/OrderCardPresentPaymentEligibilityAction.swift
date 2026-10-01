import Foundation

// Defines the actions supported by the OrderCardPresentPaymentEligibilityStore
public enum OrderCardPresentPaymentEligibilityAction: Action {
    case checkEligibility(orderID: Int64,
                          siteID: Int64,
                          cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration,
                          onCompletion: (Result<OrderCardPresentPaymentEligibility, Error>) -> Void)
}

/// A currency explanation is only relevant when the order passes the other payment checks.
public enum OrderCardPresentPaymentEligibility: Equatable {
    case eligible
    case unsupportedCurrency(String)
    case ineligible
}
