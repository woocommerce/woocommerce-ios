import Foundation
import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct PaymentCaptureWalletSuppressionTests {
    private let stores = MockStoresManager(sessionManager: .makeForTesting())
    private let walletPresentationSuppression = MockWalletPresentationSuppression()

    @Test(arguments: CardReaderType.allCases.map(\.rawValue))
    func test_collect_payment_when_reader_type_is_known_then_only_external_readers_suppress_wallet(readerTypeRawValue: String) throws {
        // Given
        let readerType = try #require(CardReaderType(rawValue: readerTypeRawValue))
        let sut = makeOrchestrator()
        var suppressionRequestsAtPaymentStart: Int?
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case .collectPayment = action else { return }
            suppressionRequestsAtPaymentStart = walletPresentationSuppression.suppressionRequestCount
        }

        // When
        collectPayment(using: sut, readerType: readerType)

        // Then
        #expect(suppressionRequestsAtPaymentStart == (readerType == .tapToPay ? 0 : 1))
    }

    @Test(arguments: [false, true])
    func test_collect_payment_when_external_reader_payment_completes_then_restores_wallet(paymentSucceeds: Bool) {
        // Given
        let sut = makeOrchestrator()
        var completePayment: ((Result<PaymentIntent, Error>) -> Void)?
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case let .collectPayment(_, _, _, _, _, _, _, completion) = action else { return }
            completePayment = completion
        }
        collectPayment(using: sut, readerType: .stripeM2)
        #expect(walletPresentationSuppression.suppressionRequestCount == 1)
        #expect(walletPresentationSuppression.restorationCount == 0)

        // When
        if paymentSucceeds {
            completePayment?(.success(.fake().copy(collectedPaymentMethod: .cardPresent(details: .fake()))))
        } else {
            completePayment?(.failure(NSError(domain: "PaymentFailure", code: 1)))
        }

        // Then
        #expect(walletPresentationSuppression.restorationCount == 1)
    }

    @Test func test_cancel_payment_when_external_reader_payment_is_canceled_then_restores_wallet() {
        // Given
        let sut = makeOrchestrator()
        var completeCancellation: ((Result<Void, Error>) -> Void)?
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case let .cancelPayment(completion) = action else { return }
            completeCancellation = completion
        }
        collectPayment(using: sut, readerType: .stripeM2)
        #expect(walletPresentationSuppression.suppressionRequestCount == 1)

        // When
        sut.cancelPayment(onCompletion: { _ in })
        completeCancellation?(.success(()))

        // Then
        #expect(walletPresentationSuppression.restorationCount == 1)
    }

    @Test func test_retry_payment_when_tap_to_pay_payment_fails_then_does_not_suppress_wallet() {
        // Given
        let sut = makeOrchestrator()
        var didRetryPayment = false
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            switch action {
            case let .collectPayment(_, _, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "PaymentFailure", code: 1)))
            case .retryPayment:
                didRetryPayment = true
            default:
                break
            }
        }
        collectPayment(using: sut, readerType: .tapToPay)

        // When
        sut.retryPayment(for: .fake(), onCompletion: { _ in })

        // Then
        #expect(didRetryPayment)
        #expect(walletPresentationSuppression.suppressionRequestCount == 0)
    }

    @Test(arguments: [CardReaderType.tapToPay.rawValue, CardReaderType.stripeM2.rawValue])
    func test_collect_payment_when_using_pos_orchestrator_then_preserves_reader_wallet_behavior(readerTypeRawValue: String) throws {
        // Given
        let readerType = try #require(CardReaderType(rawValue: readerTypeRawValue))
        let sut = CardPresentPaymentInvalidatablePaymentOrchestrator(
            stores: stores,
            celebration: MockPaymentCaptureCelebration(),
            walletPresentationSuppression: walletPresentationSuppression)

        // When
        collectPayment(using: sut, readerType: readerType)

        // Then
        #expect(walletPresentationSuppression.suppressionRequestCount == (readerType == .tapToPay ? 0 : 1))
    }

    private func makeOrchestrator() -> PaymentCaptureOrchestrator {
        PaymentCaptureOrchestrator(stores: stores,
                                   celebration: MockPaymentCaptureCelebration(),
                                   walletPresentationSuppression: walletPresentationSuppression)
    }

    private func collectPayment(using orchestrator: PaymentCaptureOrchestrating, readerType: CardReaderType) {
        orchestrator.collectPayment(for: .fake(),
                                    orderTotal: 1,
                                    paymentGatewayAccount: .fake(),
                                    readerType: readerType,
                                    paymentMethodTypes: [.cardPresent],
                                    stripeSmallestCurrencyUnitMultiplier: 100,
                                    countryCode: .US,
                                    terminalPaymentPreparationEnabled: false,
                                    channel: .storeManagement,
                                    onPreparingReader: {},
                                    onWaitingForInput: { _ in },
                                    onCardInserted: {},
                                    onProcessingMessage: {},
                                    onDisplayMessage: { _ in },
                                    onProcessingCompletion: { _ in },
                                    onCompletion: { _ in })
    }
}
