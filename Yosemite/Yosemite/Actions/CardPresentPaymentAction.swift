// MARK: - CardPresentPaymentAction: Defines all of the Actions supported by the CardPresentPaymentStore.
//

import Combine

public enum CardPresentPaymentAction: Action {
    /// Checks the onboarding state for a site.
    ///
    case checkOnboardingState(siteID: Int64, onCompletion: (CardPresentPaymentOnboardingState) -> Void)

    /// Start the Card Reader discovery process.
    ///
    case startCardReaderDiscovery(siteID: Int64, onReaderDiscovered: ([CardReader]) -> Void, onError: (Error) -> Void)

    /// Cancels the Card Reader discovery process.
    ///
    case cancelCardReaderDiscovery(onCompletion: (Result<Void, Error>) -> Void)

    /// Connect to a specific CardReader.
    /// Stops Card Reader discovery
    ///
    case connect(reader: CardReader, onCompletion: (Result<CardReader, Error>) -> Void)

    /// Disconnect from currently connected Reader
    ///
    case disconnect(onCompletion: (Result<Void, Error>) -> Void)

    /// Calls the completion block everytime the list of known readers changes
    /// with an array of readers known to us.
    ///
    /// What does "known" mean?
    /// If the user connects to a reader, we declare it known. If the user explicitly disconnects from a reader,
    /// we treat that as a "forget" request and un-declare known-ness. During discovery, if a known reader is
    /// detected, it should be connected to automatically. The list of known readers (most merchants will only
    /// have 1 or 2) will be persisted across application sessions.
    case observeKnownReaders(onCompletion: ([CardReader]) -> Void)

    /// Calls the completion block everytime the list of connected readers changes
    /// with an array of connected readers.
    ///
    case observeConnectedReaders(onCompletion: ([CardReader]) -> Void)

    /// Collected payment for an order.
    ///
    case collectPayment(siteID: Int64,
                        orderID: Int64,
                        parameters: PaymentParameters,
                        onCardReaderMessage: (CardReaderEvent) -> Void,
                        onCompletion: (Result<PaymentIntent, Error>) -> Void)

    /// Cancels an active attempt to collect a payment.
    case cancelPayment(onCompletion: ((Result<Void, Error>) -> Void)?)

    /// Check whether there is a software update available.
    case checkForCardReaderUpdate(onCompletion: (Result<CardReaderSoftwareUpdate?, Error>) -> Void)

    /// Update card reader firmware.
    case startCardReaderUpdate(onProgress: (Float) -> Void,
                        onCompletion: (Result<Void, Error>) -> Void)

    /// Restarts the card present payments system
    /// This might imply, but not be limited to:
    /// 1. Disconnect from a connected reader
    /// 2. Clear all credentials, cached data
    /// 3. Reset all status indicators
    case reset

    /// Checks if a reader is connected
    case checkCardReaderConnected(onCompletion: (AnyPublisher<[CardReader], Never>) -> Void)
}
