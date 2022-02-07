#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension ChargeStatus {

    /// Factory Method to initialize ChargeStatus with StripeTerminal's ChargeStatus
    /// - Parameter readerType: an instance of ChargeStatus, declared in StripeTerminal
    static func with(status: StripeTerminal.ChargeStatus) -> ChargeStatus {
        switch status {
        case .succeeded:
            return .succeeded
        case .pending:
            return .pending
        case .failed:
            return .failed
        default:
            return .failed
        }
    }
}
#endif
