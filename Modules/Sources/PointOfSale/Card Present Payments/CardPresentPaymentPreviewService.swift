import Foundation
import Combine
import enum Yosemite.PaymentChannel
import struct Yosemite.Order
import enum Yosemite.CardReaderSoftwareUpdateState

#if DEBUG

final class CardPresentPaymentPreviewService: CardPresentPaymentFacade {
    let paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never> = Just(.idle).eraseToAnyPublisher()

    @Published var readerConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected

    var readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never> {
        $readerConnectionStatus.eraseToAnyPublisher()
    }

    var cardReaderUpdateStatePublisher: AnyPublisher<CardReaderSoftwareUpdateState, Never> {
        Just(.none).eraseToAnyPublisher()
    }

    let isPOSCardPaymentEnabled: Bool

    init(connectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected,
         isPOSCardPaymentEnabled: Bool = true) {
        self.readerConnectionStatus = connectionStatus
        self.isPOSCardPaymentEnabled = isPOSCardPaymentEnabled
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

    func cancelPayment() async throws {
        // no-op
    }

    func cancelReconnection() async {
        // no-op
    }

    func updateCardReaderSoftware() async throws {
        // no-op
    }
}

#endif
