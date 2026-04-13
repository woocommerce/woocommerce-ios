import Foundation

/// Represents the state of a card reader auto-reconnection attempt.
/// When a Bluetooth card reader unexpectedly disconnects, the Stripe Terminal SDK
/// automatically attempts to reconnect. These states track that process.
public enum CardReaderReconnectionState: Equatable {
    /// No reconnection attempt is in progress.
    case idle

    /// The SDK is attempting to automatically reconnect to the reader.
    case reconnecting(reader: CardReader)

    /// The auto-reconnection succeeded.
    case succeeded(reader: CardReader)

    /// The auto-reconnection failed.
    case failed(reader: CardReader)
}
