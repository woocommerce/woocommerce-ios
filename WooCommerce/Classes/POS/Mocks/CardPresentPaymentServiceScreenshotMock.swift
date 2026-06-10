import Foundation
import Yosemite
import Combine
import PointOfSale

final class CardPresentPaymentServiceScreenshotMock: CardPresentPaymentFacade {
    let paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never>
    let readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never>
    let cardReaderUpdateStatePublisher: AnyPublisher<CardReaderSoftwareUpdateState, Never>

    private let paymentEventSubject = PassthroughSubject<CardPresentPaymentEvent, Never>()
    private let readerConnectionStatusSubject: CurrentValueSubject<CardPresentPaymentReaderConnectionStatus, Never>

    init(startsConnected: Bool = true) {
        paymentEventPublisher = paymentEventSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        let mockReader = CardPresentPaymentCardReader(
            name: "Simulated POS E",
            batteryLevel: 0.5,
            softwareVersion: "1.00.03.34-SZZZ_Generic_v45-300001"
        )
        readerConnectionStatusSubject = CurrentValueSubject(startsConnected ? .connected(mockReader) : .disconnected)
        readerConnectionStatusPublisher = readerConnectionStatusSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        // No updates needed for screenshots
        cardReaderUpdateStatePublisher = Just(.none)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        let mockReader = CardPresentPaymentCardReader(
            name: "Simulated POS E",
            batteryLevel: 0.5,
            softwareVersion: "1.00.03.34-SZZZ_Generic_v45-300001"
        )

        try await Task.sleep(nanoseconds: 100_000_000)
        readerConnectionStatusSubject.send(.connected(mockReader))
        return .connected(mockReader)
    }

    func disconnectReader() async {
        readerConnectionStatusSubject.send(.disconnected)
    }

    func updateCardReaderSoftware() async throws {
        // No-op for screenshots
    }

    func collectPayment(for order: Order, using connectionMethod: CardReaderConnectionMethod, channel: PaymentChannel) async throws -> CardPresentPaymentResult {

        // 1. Validating order
        paymentEventSubject.send(.show(eventDetails: .validatingOrder(cancelPayment: {})))
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // 2. Preparing reader
        paymentEventSubject.send(.show(eventDetails: .preparingForPayment(cancelPayment: {})))
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // 3. Ready to accept card
        let inputMethods: Yosemite.CardReaderInput = [.tap, .swipe, .insert]
        paymentEventSubject.send(.show(eventDetails: .tapSwipeOrInsertCard(inputMethods: inputMethods, cancelPayment: {})))
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // 4. Processing and success
        paymentEventSubject.send(.show(eventDetails: .processing))
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        paymentEventSubject.send(.show(eventDetails: .paymentSuccess(done: {})))

        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds, give it some time for the screenshot

        return .success(CardPresentPaymentTransaction())
    }

    func cancelPayment() {
        // No-op for screenshots
    }

    func cancelPayment() async throws {
        // No-op for screenshots
    }

    func cancelReconnection() async {
        // No-op for screenshots
    }
}
