import Foundation
import Yosemite
import Combine
import PointOfSale

final class CardPresentPaymentServiceScreenshotMock: CardPresentPaymentFacade {
    let paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never>
    let readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never>
    let cardReaderUpdateStatePublisher: AnyPublisher<CardReaderSoftwareUpdateState, Never>

    private let paymentEventSubject = PassthroughSubject<CardPresentPaymentEvent, Never>()

    init() {
        paymentEventPublisher = paymentEventSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        // Always return a connected card reader for screenshots
        let mockReader = CardPresentPaymentCardReader(
            name: "Simulated POS E",
            batteryLevel: 0.5,
            softwareVersion: "1.00.03.34-SZZZ_Generic_v45-300001"
        )
        readerConnectionStatusPublisher = Just(.connected(mockReader))
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        // No updates needed for screenshots
        cardReaderUpdateStatePublisher = Just(.none)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        // Return connected reader immediately
        let mockReader = CardPresentPaymentCardReader(
            name: "Simulated POS E",
            batteryLevel: 0.5,
            softwareVersion: "1.00.03.34-SZZZ_Generic_v45-300001"
        )
        return .connected(mockReader)
    }

    func disconnectReader() async {
        // No-op for screenshots
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
