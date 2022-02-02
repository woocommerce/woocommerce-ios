#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension PaymentMethod {
    /// Failable initializer.
    /// Maps a SCPPaymentMethodDetails to PaymentMethod
    init?(method: StripeTerminal.PaymentMethodDetails?) {
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
            self = .presentCard(details: CardPresentTransactionDetails(details: details))
        case .unknown:
            self = .unknown
        default:
            self = .unknown
        }
    }
}
#endif
