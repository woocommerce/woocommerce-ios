import Foundation
import Yosemite
import Combine
import PointOfSale

@MainActor
final class CardPresentPaymentServiceScreenshotMock: CardPresentPaymentFacade {
    @Published var paymentSessionState: CardPresentPaymentSessionState = .idle
    var paymentSessionStatePublisher: AnyPublisher<CardPresentPaymentSessionState, Never> {
        $paymentSessionState.eraseToAnyPublisher()
    }

    let paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never>
    let readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never>
    let cardReaderUpdateStatePublisher: AnyPublisher<CardReaderSoftwareUpdateState, Never>

    private var paymentAttemptID: UUID?
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
        guard paymentAttemptID == nil else { return .cancellation }
        let attemptID = UUID()
        paymentAttemptID = attemptID
        paymentSessionState = .active
        defer { if paymentAttemptID == attemptID { finishMockPayment() } }

        // 1. Validating order
        paymentEventSubject.send(.show(eventDetails: .validatingOrder(cancelPayment: {})))
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        guard paymentAttemptID == attemptID else { return .cancellation }

        // 2. Preparing reader
        paymentEventSubject.send(.show(eventDetails: .preparingForPayment(cancelPayment: {})))
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        guard paymentAttemptID == attemptID else { return .cancellation }

        // 3. Ready to accept card
        let inputMethods: Yosemite.CardReaderInput = [.tap, .swipe, .insert]
        paymentEventSubject.send(.show(eventDetails: .tapSwipeOrInsertCard(inputMethods: inputMethods, cancelPayment: {})))

        try await Task.sleep(nanoseconds: UInt64(mockCardWaitInterval * 1_000_000_000))
        guard paymentAttemptID == attemptID else { return .cancellation }

        return .success(CardPresentPaymentTransaction())
    }

    func cancelPayment() { finishMockPayment() }

    func cancelPayment() async throws { finishMockPayment() }

    private var mockCardWaitInterval: TimeInterval {
        #if DEBUG
        if let value = ProcessInfo.processInfo.environment["POS_MOCK_CARD_PAYMENT_WAIT_SECONDS"],
           let interval = TimeInterval(value), interval.isFinite, (1...300).contains(interval) {
            return interval
        }
        #endif
        return 3
    }

    private func finishMockPayment() {
        paymentAttemptID = nil
        paymentSessionState = .idle
    }

    func cancelReconnection() async {
        // No-op for screenshots
    }
}
