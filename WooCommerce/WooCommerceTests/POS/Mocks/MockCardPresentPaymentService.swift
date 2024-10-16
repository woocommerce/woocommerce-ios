import Foundation
import Combine
import struct Yosemite.Order
@testable import WooCommerce

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
    func collectPayment(for order: Yosemite.Order, using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentResult {
        onCollectPaymentCalled?()
        paymentEvent = .show(eventDetails: CardPresentPaymentEventDetails.paymentSuccess(done: {}))
        return .success(CardPresentPaymentTransaction(receiptURL: URL(string: "https://example.net/receipts/123")!))
    }

    func cancelPayment() {
        cancelPaymentCalled = true
    }
}
