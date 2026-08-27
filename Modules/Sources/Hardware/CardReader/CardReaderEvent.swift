/// The possible events from a connected reader.
public enum CardReaderEvent: Equatable {
    /// The reader begins waiting for input.
    /// The app should prompt the customer to present a payment method
    case waitingForInput(CardReaderInput)

    /// Request that a prompt be displayed in the app.
    /// For example, if the prompt is SwipeCard,
    /// the app should instruct the user to present the card again by swiping it.
    case displayMessage(CardReaderDisplayMessage)

    /// The reader has accepted cardholder input and the card can be removed.
    case removeCardRequested(String)

    /// A card was inserted.
    case cardInserted

    /// A card was removed.
    case cardRemoved

    /// A card was removed after client-side payment capture.
    case cardRemovedAfterClientSidePaymentCapture

    /// Card details were collected, and can be used to process a payment.
    case cardDetailsCollected

    /// Low battery warning.
    case lowBattery

    /// Low battery warning resolved.
    case lowBatteryResolved

    /// The card reader disconnected.
    case disconnected
}

/// A message that a connected reader requests the app to display.
public enum CardReaderDisplayMessage: Equatable {
    /// A reader message that does not require specialized presentation behavior.
    case generic(String)

    /// The reader detected more than one contactless card or NFC device.
    case multipleContactlessCardsDetected(String)

    public var text: String {
        switch self {
        case .generic(let message), .multipleContactlessCardsDetected(let message):
            message
        }
    }
}
