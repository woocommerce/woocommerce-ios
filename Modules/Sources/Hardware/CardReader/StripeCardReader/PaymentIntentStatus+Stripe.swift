#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension PaymentIntentStatus {

    /// Factory Method to initialize PaymentItemStatus with StripeTerminal's PaymentIntentStatus
    /// - Parameter status: an instance of PaymentIntentStatus, declared in StripeTerminal
    static func with(status: StripeTerminal.PaymentIntentStatus) -> PaymentIntentStatus {
        switch status {
        case .requiresPaymentMethod:
            return .requiresPaymentMethod
        case .requiresCapture:
            return .requiresCapture
        case .requiresConfirmation:
            return .requiresConfirmation
        case .processing:
            return .processing
        case .canceled:
            return .canceled
        case .succeeded:
            return .succeeded
        default:
            return .canceled
        }
    }
}
#endif
