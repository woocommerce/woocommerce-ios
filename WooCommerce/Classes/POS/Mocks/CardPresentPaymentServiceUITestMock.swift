#if DEBUG

import Combine
import Foundation
import PointOfSale
import Yosemite

final class CardPresentPaymentServiceUITestMock: CardPresentPaymentFacade {
    let paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never>
    let readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never>
    let cardReaderUpdateStatePublisher: AnyPublisher<CardReaderSoftwareUpdateState, Never>

    private let paymentEventSubject = PassthroughSubject<CardPresentPaymentEvent, Never>()
    private let readerConnectionStatusSubject: CurrentValueSubject<CardPresentPaymentReaderConnectionStatus, Never>

    init() {
        paymentEventPublisher = paymentEventSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        readerConnectionStatusSubject = CurrentValueSubject(.disconnected)
        readerConnectionStatusPublisher = readerConnectionStatusSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        cardReaderUpdateStatePublisher = Just(.none)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        try await Task.sleep(nanoseconds: 100_000_000)
        readerConnectionStatusSubject.send(.connected(Self.mockReader))
        return .connected(Self.mockReader)
    }

    func disconnectReader() async {
        readerConnectionStatusSubject.send(.disconnected)
    }

    func updateCardReaderSoftware() async throws {
        // No-op for UI tests.
    }

    func collectPayment(for order: Order, using connectionMethod: CardReaderConnectionMethod, channel: PaymentChannel) async throws -> CardPresentPaymentResult {
        paymentEventSubject.send(.show(eventDetails: .validatingOrder(cancelPayment: {})))
        try await Task.sleep(nanoseconds: 100_000_000)

        paymentEventSubject.send(.show(eventDetails: .preparingForPayment(cancelPayment: {})))
        try await Task.sleep(nanoseconds: 100_000_000)

        let inputMethods: Yosemite.CardReaderInput = [.tap, .swipe, .insert]
        paymentEventSubject.send(.show(eventDetails: .tapSwipeOrInsertCard(inputMethods: inputMethods, cancelPayment: {})))
        try await Task.sleep(nanoseconds: 100_000_000)

        paymentEventSubject.send(.show(eventDetails: .processing))
        try await Task.sleep(nanoseconds: 100_000_000)

        paymentEventSubject.send(.show(eventDetails: .paymentSuccess(done: {})))
        return .success(CardPresentPaymentTransaction())
    }

    func cancelPayment() {
        // No-op for UI tests.
    }

    func cancelPayment() async throws {
        // No-op for UI tests.
    }

    func cancelReconnection() async {
        // No-op for UI tests.
    }
}

private extension CardPresentPaymentServiceUITestMock {
    static let mockReader = CardPresentPaymentCardReader(
        name: "Simulated POS E",
        batteryLevel: 0.5,
        softwareVersion: "1.00.03.34-SZZZ_Generic_v45-300001"
    )
}

#endif
