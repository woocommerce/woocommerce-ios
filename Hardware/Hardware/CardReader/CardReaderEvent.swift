/// An event dispatched by  a connected reader.
/// It wraps an event type and an optional user-facing message
public struct CardReaderEvent {
    public let type: CardReaderEventType
    public let message: String?

    init(type: CardReaderEventType, message: String? = nil) {
        self.type = type
        self.message = message
    }
}

/// The possible events from a connected reader.
public enum CardReaderEventType {
    /// The reader begins waiting for input.
    /// The app should prompt the customer to present a payment method
    case waitingForInput

    /// Request that a prompt be displayed in the app.
    /// For example, if the prompt is SwipeCard,
    /// the app should instruct the user to present the card again by swiping it.
    case displayMessage

    // A card was inserted.
    case cardInserted

    // A card was removed.
    case cardRemoved

    // Low battery warning.
    case lowBattery

    // Low battery warning resolved.
    case lowBatteryResolved

    // A software update is available.
    case softwareUpdateNeeded

    // Software is up to dat.
    case softwareUpToDate

    // The card reader disconnected.
    case disconnected
}
