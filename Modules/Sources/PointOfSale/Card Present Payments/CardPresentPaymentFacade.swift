import Foundation
import enum Yosemite.PaymentChannel
import struct Yosemite.Order
import enum Yosemite.CardReaderSoftwareUpdateState
import Combine

public protocol CardPresentPaymentFacade {
    /// Whether card-present payments should be exposed in POS for the merchant's store.
    ///
    /// Derived from the underlying `CardPresentPaymentsConfiguration.isPOSCardPaymentEnabled`
    /// — see that extension for the per-country rules (Canada is currently the only explicit
    /// override). Views consume this through `POSPaymentModel.isPOSCardPaymentEnabled` to decide
    /// whether to render the card-reader / TTP UI or fall back to the cash + secondary-method
    /// promoted layout.
    var isPOSCardPaymentEnabled: Bool { get }

    /// `paymentEventPublisher` provides a stream of events relating to a payment, including their view models,
    /// for subscribers to display to the user. e.g. onboarding screens, connection progress, payment progress, card reader messages.
    /// This is a long lasting stream, and will not finish during the life of the façade, instead it will publish events for each payment attempt.
    var paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never> { get }

    /// `readerConnectionStatusPublisher` provides the latest connection status for the card reader.
    /// This is a long lasting stream, and will not finish during the life of the façade.
    var readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never> { get }

    /// `cardReaderUpdateStatePublisher` provides the latest software update state for the connected card reader.
    /// This is a long lasting stream, and will not finish during the life of the façade.
    var cardReaderUpdateStatePublisher: AnyPublisher<CardReaderSoftwareUpdateState, Never> { get }

    /// Attempts to a card reader of the specified type.
    /// If another type of reader is already connected, this will be disconnected automatically.
    /// - Parameters:
    ///   - connectionMethod: Allows specifying Tap to Pay or bluetooth reader.
    /// - Returns: `CardPresentPaymentReaderConnectionResult` for a success, or cancellation.
    /// - Throws: `CardPresentPaymentError` for any failures,
    /// - Output: publishes intermediate events on the `paymentEventPublisher` as required.
    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult

    /// Disconnects the currently connected card reader, if present.
    /// Also cancels any in-progress payment, if possible.
    func disconnectReader() async

    /// Starts a software update for the currently connected card reader, if an update is available.
    /// - Throws: `CardPresentPaymentError` for any failures.
    /// - Output: publishes intermediate events on the `paymentEventPublisher` as required.
    func updateCardReaderSoftware() async throws

    /// Collects a card present payment for an order.
    /// If the appropriate type of reader is not already connected, this should attempt a connection before the payment.
    /// If another type of reader is already connected, this will be disconnected automatically.
    /// - Parameters:
    ///   - order: The order to collect payment for
    ///   - connectionMethod: Allows specifying Tap to Pay or bluetooth reader.
    ///   - channel: The channel where the payment is being collected.
    /// - Returns: `CardPresentPaymentResult` for a success, or cancellation.
    /// - Throws: `CardPresentPaymentError` for any failures.
    /// - Output: publishes intermediate events on the `paymentEventPublisher` as required.
    func collectPayment(for order: Order,
                        using connectionMethod: CardReaderConnectionMethod,
                        channel: PaymentChannel) async throws -> CardPresentPaymentResult

    /// Cancels any in-progress payment.
    func cancelPayment()

    /// Cancels any in-progress payment, returning when complete
    func cancelPayment() async throws

    /// Cancels an in-progress auto-reconnection attempt.
    /// Use this when the user wants to manually connect a different reader
    /// or cancel the automatic reconnection process.
    func cancelReconnection() async
}
