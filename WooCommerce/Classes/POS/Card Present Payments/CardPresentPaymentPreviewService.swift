import Foundation
import Combine
import struct Yosemite.Order

#if DEBUG

struct CardPresentPaymentPreviewService: CardPresentPaymentFacade {
    let paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never> = Just(.idle).eraseToAnyPublisher()

    let connectedReaderPublisher: AnyPublisher<CardPresentPaymentCardReader?, Never> = Just(nil).eraseToAnyPublisher()

    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        .connected(CardPresentPaymentCardReader(name: "Test reader", batteryLevel: 0.85))
    }

    func disconnectReader() {
        // no-op
    }

    func collectPayment(for order: Yosemite.Order, using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentResult {
        .success(CardPresentPaymentTransaction(receiptURL: URL(string: "https://example.net/receipts/123")!))
    }

    func cancelPayment() {
        // no-op
    }
}

#endif
