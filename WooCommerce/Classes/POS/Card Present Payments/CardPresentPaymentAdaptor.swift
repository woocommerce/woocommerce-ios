import Combine
import struct Yosemite.Order
import Foundation
import class WooFoundation.CurrencyFormatter

final class CardPresentPaymentsAdaptor: CardPresentPaymentFacade {
    var paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never> {
        paymentEventSubject.eraseToAnyPublisher()
    }

    var connectedReaderPublisher: AnyPublisher<CardPresentPaymentCardReader?, Never> {
        connectedReaderSubject.eraseToAnyPublisher()
    }

    private let paymentEventSubject = CurrentValueSubject<CardPresentPaymentEvent, Never>(.idle)
    private let connectedReaderSubject = CurrentValueSubject<CardPresentPaymentCardReader?, Never>(nil)

    @MainActor
    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        // TODO: replace it with reader connection
        let mockReader = CardPresentPaymentCardReader(name: "Test Reader", batteryLevel: 0.5)
        connectedReaderSubject.send(mockReader)
        return .connected(mockReader)
    }

    func disconnectReader() {
    }

    func collectPayment(for order: Order, using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentResult {
        // TODO: replace it with payment collection
        .cancellation
    }

    func cancelPayment() {
    }
}
