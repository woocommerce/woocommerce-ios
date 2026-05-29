#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension CardReaderEvent {
    /// Factory method
    /// - Parameter readerInputOptions: An instance of a StripeTerminal.ReaderInputOptions
    static func make(stripeReaderInputOptions: ReaderInputOptions) -> Self {
        let inputOptions = CardReaderInput(stripeReaderInputOptions: stripeReaderInputOptions)
        return .waitingForInput(inputOptions)
    }

    /// Factory method
    /// - Parameter readerInputOptions: An instance of a StripeTerminal.ReaderDisplayMessage
    static func make(displayMessage: ReaderDisplayMessage) -> Self {
        switch displayMessage {
        case .removeCard:
            return .removeCardRequested(displayMessage.localizedMessage)
        default:
            return .displayMessage(displayMessage.localizedMessage)
        }
    }
}
#endif
