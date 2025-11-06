import Foundation
import Combine
import enum Yosemite.PaymentChannel
import struct Yosemite.Order

#if DEBUG

final class CardPresentPaymentPreviewService: CardPresentPaymentFacade {
    let paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never> = Just(.idle).eraseToAnyPublisher()

    @Published var readerConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected

    var readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never> {
        $readerConnectionStatus.eraseToAnyPublisher()
    }

    init(connectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected) {
        self.readerConnectionStatus = connectionStatus
    }

    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        .connected(CardPresentPaymentCardReader(name: "Test reader", batteryLevel: 0.85))
    }

    func disconnectReader() {
        // no-op
    }

    func collectPayment(for order: Yosemite.Order,
                        using connectionMethod: CardReaderConnectionMethod,
                        channel: PaymentChannel) async throws -> CardPresentPaymentResult {
        .success(CardPresentPaymentTransaction())
    }

    func cancelPayment() {
        // no-op
    }

    func updateCardReaderSoftware() async throws {
        // no-op
    }
}

#endif
