import StripeTerminal

extension PaymentMethodType {
    init(methodType: SCPPaymentMethodType) {
        switch methodType {
        case .card:
            self = .card
        case .cardPresent:
            self = .presentCard
        case .unknown:
            self = .unknown
        default:
            self = .unknown
        }
    }
}
