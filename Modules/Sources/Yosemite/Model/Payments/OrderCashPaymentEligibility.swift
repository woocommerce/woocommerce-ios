public enum OrderCashPaymentEligibility: Equatable, Sendable {
    case eligible
    case authorizedCardPayment
    case alreadyPaid
    case unresolvedCardPayment
}
