// MARK: - CardPresentPaymentAction: Defines all of the Actions supported by the CardPresentPaymentStore.
//

import Combine

public enum CardPresentPaymentAction: Action {
    /// Sets the store to use a given payment gateway
    ///
    case use(paymentGatewayAccount: PaymentGatewayAccount)

    /// Retrieves the current configuration for IPP.
    ///
    case loadActivePaymentGatewayExtension(onCompletion: (CardPresentPaymentGatewayExtension) -> Void)

    /// Retrieves and stores payment gateway account(s) for the provided `siteID`
    /// We support payment gateway accounts for both the WooCommerce Payments extension AND
    /// the Stripe extension. Let's attempt to load each and update view storage with the results.
    /// Calls the passed completion with success after both loads have been attempted.
    ///
    case loadAccounts(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)

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
                        onProcessingCompletion: (PaymentIntent) -> Void,
                        onCompletion: (Result<PaymentIntent, Error>) -> Void)

    /// Returns a publisher that captures payment on the server side after successful payment capture on the client side.
    /// Currently used for retry after receiving an error from server-side payment capture.
    case capturePayment(siteID: Int64,
                        orderID: Int64,
                        paymentIntent: PaymentIntent,
                        onCompletion: (AnyPublisher<Result<PaymentIntent, Error>, Never>) -> Void)

    /// Cancels an active attempt to collect a payment.
    case cancelPayment(onCompletion: ((Result<Void, Error>) -> Void)?)

    /// Refund payment of an order, client side. Only for use on Interac payments
    ///
    case refundPayment(parameters: RefundParameters, onCardReaderMessage: (CardReaderEvent) -> Void, onCompletion: ((Result<Void, Error>) -> Void)?)

    /// Cancels a refund, if one is in progress
    case cancelRefund(onCompletion: ((Result<Void, Error>) -> Void)?)

    /// Check the state of available software updates.
    case observeCardReaderUpdateState(onCompletion: (AnyPublisher<CardReaderSoftwareUpdateState, Never>) -> Void)

    /// Update card reader firmware.
    case startCardReaderUpdate

    /// Restarts the card present payments system
    /// This might imply, but not be limited to:
    /// 1. Disconnect from a connected reader
    /// 2. Clear all credentials, cached data
    /// 3. Reset all status indicators
    case reset

    /// Provides a publisher for card reader connections
    case publishCardReaderConnections(onCompletion: (AnyPublisher<[CardReader], Never>) -> Void)

    /// Fetches Charge details by charge ID
    ///
    case fetchWCPayCharge(siteID: Int64, chargeID: String, onCompletion: (Result<WCPayCharge, Error>) -> Void)
}
