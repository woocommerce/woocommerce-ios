import Foundation
import Combine
import enum Yosemite.PaymentChannel
import struct Yosemite.Order
import enum Yosemite.CardReaderSoftwareUpdateState
@testable import PointOfSale

final class MockCardPresentPaymentService: CardPresentPaymentFacade {
    // MARK: - Variables for emitting events in unit tests

    @Published var paymentEvent: CardPresentPaymentEvent = .idle
    @Published var connectedReader: CardPresentPaymentCardReader?

    var cancelPaymentCalled = false

    // MARK: - CardPresentPaymentFacade

    var paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never> {
        $paymentEvent.eraseToAnyPublisher()
    }

    var readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never> {
        $connectedReader.map { reader -> CardPresentPaymentReaderConnectionStatus in
            guard let reader else {
                return .disconnected
            }
            return .connected(reader)
        }
        .eraseToAnyPublisher()
    }

    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        .connected(CardPresentPaymentCardReader(name: "Test reader", batteryLevel: 0.85))
    }

    func disconnectReader() async {
        connectedReader = nil
    }

    var onCollectPaymentCalled: (() -> Void)?
    var collectPaymentWasCalled = false
    var collectPaymentChannel: PaymentChannel?
    func collectPayment(for order: Yosemite.Order,
                        using connectionMethod: CardReaderConnectionMethod,
                        channel: PaymentChannel) async throws -> CardPresentPaymentResult {
        collectPaymentWasCalled = true
        collectPaymentChannel = channel
        onCollectPaymentCalled?()
        paymentEvent = .show(eventDetails: CardPresentPaymentEventDetails.paymentSuccess(done: {}))
        return .success(CardPresentPaymentTransaction())
    }

    func cancelPayment() {
        cancelPaymentCalled = true
    }

    var onCancelPaymentCalled: (() async throws -> Void)?
    func cancelPayment() async throws {
        cancelPaymentCalled = true
        try await onCancelPaymentCalled?()
    }

    var cardReaderUpdateStatePublisher: AnyPublisher<CardReaderSoftwareUpdateState, Never> = Just(.none).eraseToAnyPublisher()

    func updateCardReaderSoftware() async throws {
        // no-op
    }
}
