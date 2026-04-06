import Foundation
import Combine
import PointOfSale
import struct Yosemite.Order
import enum Yosemite.PaymentChannel
import enum Yosemite.CardReaderSoftwareUpdateState
import struct Yosemite.CardReaderInput

final class StatefulPaymentService: CardPresentPaymentFacade, Observable {
    let configuration: MockConfiguration

    let paymentEventSubject = CurrentValueSubject<CardPresentPaymentEvent, Never>(.idle)
    let readerConnectionStatusSubject: CurrentValueSubject<CardPresentPaymentReaderConnectionStatus, Never>
    private let cardReaderUpdateStateSubject = CurrentValueSubject<CardReaderSoftwareUpdateState, Never>(.none)

    var paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never> {
        paymentEventSubject.eraseToAnyPublisher()
    }

    var readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never> {
        readerConnectionStatusSubject.eraseToAnyPublisher()
    }

    var cardReaderUpdateStatePublisher: AnyPublisher<CardReaderSoftwareUpdateState, Never> {
        cardReaderUpdateStateSubject.eraseToAnyPublisher()
    }

    init(configuration: MockConfiguration) {
        self.configuration = configuration
        self.readerConnectionStatusSubject = CurrentValueSubject(configuration.initialReaderConnectionStatus)
    }

    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        paymentEventSubject.send(.show(eventDetails: .scanningForReaders(endSearch: {})))
        try await Task.sleep(nanoseconds: 500_000_000)

        paymentEventSubject.send(.show(eventDetails: .connectingToReader))
        try await Task.sleep(nanoseconds: 500_000_000)

        let reader = CardPresentPaymentCardReader(name: "Prototype Reader", batteryLevel: 0.95)
        readerConnectionStatusSubject.send(.connected(reader))

        paymentEventSubject.send(.show(eventDetails: .connectionSuccess(done: {})))
        try await Task.sleep(nanoseconds: 300_000_000)

        paymentEventSubject.send(.idle)
        return .connected(reader)
    }

    func disconnectReader() async {
        readerConnectionStatusSubject.send(.disconnecting)
        try? await Task.sleep(nanoseconds: 200_000_000)
        readerConnectionStatusSubject.send(.disconnected)
        paymentEventSubject.send(.idle)
    }

    func updateCardReaderSoftware() async throws {
        // no-op for prototype
    }

    func collectPayment(for order: Order,
                        using connectionMethod: CardReaderConnectionMethod,
                        channel: PaymentChannel) async throws -> CardPresentPaymentResult {
        switch configuration.paymentSequence {
        case .successAfterDelay(let totalDelay):
            return try await runSuccessSequence(totalDelay: totalDelay)
        case .failAtStep(let failStep, let message):
            return try await runFailSequence(failAtStep: failStep, message: message)
        case .readerDisconnectsDuring(let step):
            return try await runDisconnectSequence(disconnectAtStep: step)
        case .cashOnly:
            throw NSError(domain: "POSPrototype", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "This scenario only supports cash payments"
            ])
        }
    }

    func cancelPayment() {
        paymentEventSubject.send(.idle)
    }

    func cancelPayment() async throws {
        paymentEventSubject.send(.idle)
    }
}

// MARK: - Payment Sequences

private extension StatefulPaymentService {
    func runSuccessSequence(totalDelay: TimeInterval) async throws -> CardPresentPaymentResult {
        let stepDelay = UInt64(totalDelay / 6.0 * 1_000_000_000)

        paymentEventSubject.send(.show(eventDetails: .validatingOrder(cancelPayment: {})))
        try await Task.sleep(nanoseconds: stepDelay)

        paymentEventSubject.send(.show(eventDetails: .preparingForPayment(cancelPayment: {})))
        try await Task.sleep(nanoseconds: stepDelay)

        paymentEventSubject.send(.show(eventDetails: .tapSwipeOrInsertCard(inputMethods: [], cancelPayment: {})))
        try await Task.sleep(nanoseconds: stepDelay)

        paymentEventSubject.send(.show(eventDetails: .cardInserted(cancelPayment: {})))
        try await Task.sleep(nanoseconds: stepDelay)

        paymentEventSubject.send(.show(eventDetails: .processing))
        try await Task.sleep(nanoseconds: stepDelay)

        paymentEventSubject.send(.show(eventDetails: .paymentSuccess(done: {})))
        try await Task.sleep(nanoseconds: stepDelay)

        paymentEventSubject.send(.idle)
        return .success(CardPresentPaymentTransaction())
    }

    func runFailSequence(failAtStep: PaymentStep, message: String) async throws -> CardPresentPaymentResult {
        let stepDelay: UInt64 = 400_000_000

        let steps: [PaymentStep] = [.scanning, .connecting, .preparingReader, .acceptingCard, .cardInserted, .processing, .success]

        for step in steps {
            if step == failAtStep {
                let error = NSError(domain: "POSPrototype", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: message
                ])
                paymentEventSubject.send(.show(eventDetails: .paymentError(
                    error: error,
                    retryApproach: .tryAgain(retryAction: {}),
                    cancelPayment: {}
                )))
                throw error
            }
            publishEventForStep(step)
            try await Task.sleep(nanoseconds: stepDelay)
        }

        paymentEventSubject.send(.idle)
        return .success(CardPresentPaymentTransaction())
    }

    func runDisconnectSequence(disconnectAtStep: PaymentStep) async throws -> CardPresentPaymentResult {
        let stepDelay: UInt64 = 400_000_000

        let steps: [PaymentStep] = [.scanning, .connecting, .preparingReader, .acceptingCard, .cardInserted, .processing, .success]

        for step in steps {
            if step == disconnectAtStep {
                readerConnectionStatusSubject.send(.disconnected)
                let error = NSError(domain: "POSPrototype", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "Card reader disconnected"
                ])
                paymentEventSubject.send(.show(eventDetails: .paymentError(
                    error: error,
                    retryApproach: .tryAgain(retryAction: {}),
                    cancelPayment: {}
                )))
                throw error
            }
            publishEventForStep(step)
            try await Task.sleep(nanoseconds: stepDelay)
        }

        paymentEventSubject.send(.idle)
        return .success(CardPresentPaymentTransaction())
    }

    func publishEventForStep(_ step: PaymentStep) {
        switch step {
        case .scanning:
            paymentEventSubject.send(.show(eventDetails: .validatingOrder(cancelPayment: {})))
        case .connecting:
            paymentEventSubject.send(.show(eventDetails: .connectingToReader))
        case .preparingReader:
            paymentEventSubject.send(.show(eventDetails: .preparingForPayment(cancelPayment: {})))
        case .acceptingCard:
            paymentEventSubject.send(.show(eventDetails: .tapSwipeOrInsertCard(inputMethods: [], cancelPayment: {})))
        case .cardInserted:
            paymentEventSubject.send(.show(eventDetails: .cardInserted(cancelPayment: {})))
        case .processing:
            paymentEventSubject.send(.show(eventDetails: .processing))
        case .success:
            paymentEventSubject.send(.show(eventDetails: .paymentSuccess(done: {})))
        }
    }
}
