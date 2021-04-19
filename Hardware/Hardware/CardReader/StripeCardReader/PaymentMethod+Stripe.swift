import StripeTerminal

extension PaymentMethod {
    init?(method: SCPPaymentMethodDetails?) {
        guard let method = method else {
            return nil
        }

        switch method.type {
        case .card:
            self = .card
        case .cardPresent:
            guard let details = method.cardPresent else {
                self = .unknown
                return
            }
            self = .presentCard(details: CardPresentDetails(details: details))
        case .unknown:
            self = .unknown
        default:
            self = .unknown
        }
    }
}
