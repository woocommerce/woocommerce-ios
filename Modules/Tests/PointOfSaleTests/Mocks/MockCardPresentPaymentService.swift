import Foundation
import Combine
import enum Yosemite.PaymentChannel
import struct Yosemite.Order
import enum Yosemite.CardReaderSoftwareUpdateState
@testable import PointOfSale

final class MockCardPresentPaymentService: CardPresentPaymentFacade {
    // MARK: - Variables for emitting events in unit tests

    @Published var paymentEvent: CardPresentPaymentEvent = .idle
    @Published var connectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected

    var connectedReader: CardPresentPaymentCardReader? {
        get {
            if case .connected(let reader) = connectionStatus {
                return reader
            }
            return nil
        }
        set {
            if let reader = newValue {
                connectionStatus = .connected(reader)
            } else {
                connectionStatus = .disconnected
            }
        }
    }

    var cancelPaymentCalled = false
    var connectReaderCallCount = 0
    private var connectReaderContinuation: CheckedContinuation<CardPresentPaymentReaderConnectionResult, Error>?
    var shouldSuspendConnectReader = false
    var connectReaderResult: CardPresentPaymentReaderConnectionResult = .connected(
        CardPresentPaymentCardReader(name: "Test reader", batteryLevel: 0.85)
    )

    // MARK: - CardPresentPaymentFacade

    var paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never> {
        $paymentEvent.eraseToAnyPublisher()
    }

    var readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never> {
        $connectionStatus.eraseToAnyPublisher()
    }

    var onConnectReaderCalled: (() -> Void)?

    @MainActor
    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        connectReaderCallCount += 1
        onConnectReaderCalled?()
        if shouldSuspendConnectReader {
            return try await withCheckedThrowingContinuation { continuation in
                connectReaderContinuation = continuation
            }
        }
        return connectReaderResult
    }

    func resumeConnectReader(with result: CardPresentPaymentReaderConnectionResult) {
        connectReaderContinuation?.resume(returning: result)
        connectReaderContinuation = nil
    }

    func failConnectReader(with error: Error) {
        connectReaderContinuation?.resume(throwing: error)
        connectReaderContinuation = nil
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

    var cancelReconnectionCalled = false
    var onCancelReconnectionCalled: (() async -> Void)?
    func cancelReconnection() async {
        cancelReconnectionCalled = true
        await onCancelReconnectionCalled?()
    }
}
