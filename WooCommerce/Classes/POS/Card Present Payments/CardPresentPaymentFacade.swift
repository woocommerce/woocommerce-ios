import Foundation
import struct Yosemite.Order
import Combine

protocol CardPresentPaymentFacade {
    /// `paymentEventPublisher` provides a stream of events relating to a payment, including their view models,
    /// for subscribers to display to the user. e.g. onboarding screens, connection progress, payment progress, card reader messages.
    /// This is a long lasting stream, and will not finish during the life of the façade, instead it will publish events for each payment attempt.
    var paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never> { get }

    /// `connectedReaderPublisher` provides the latest CardReader that was connected.
    /// This is a long lasting stream, and will not finish during the life of the façade.
    var connectedReaderPublisher: AnyPublisher<CardPresentPaymentCardReader?, Never> { get }

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

    /// Collects a card present payment for an order.
    /// If the appropriate type of reader is not already connected, this should attempt a connection before the payment.
    /// If another type of reader is already connected, this will be disconnected automatically.
    /// - Parameters:
    ///   - order: The order to collect payment for
    ///   - connectionMethod: Allows specifying Tap to Pay or bluetooth reader.
    /// - Returns: `CardPresentPaymentResult` for a success, or cancellation.
    /// - Throws: `CardPresentPaymentError` for any failures.
    /// - Output: publishes intermediate events on the `paymentEventPublisher` as required.
    func collectPayment(for order: Order,
                        using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentResult

    /// Cancels any in-progress payment.
    func cancelPayment()
}
