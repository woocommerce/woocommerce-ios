import Foundation

public enum OrderCardPresentPaymentEligibilityAction: Action {
case orderIsEligibleForCardPresentPayment(orderID: Int64,
                                          siteID: Int64,
                                          cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration,
                                          onCompletion: (Result<Bool, Error>) -> Void)
}
