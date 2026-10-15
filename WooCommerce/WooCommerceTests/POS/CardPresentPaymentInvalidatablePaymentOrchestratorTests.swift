import Testing
import Foundation
import Yosemite
import WooFoundation
@testable import PointOfSale
@testable import WooCommerce

@MainActor
struct CardPresentPaymentInvalidatablePaymentOrchestratorTests {
    private let stores = MockStoresManager(sessionManager: .makeForTesting())
    private let paymentSettings = MockPOSPaymentSettingsService()
    private let celebration = MockPaymentCaptureCelebration()

    init() {
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case let .collectPayment(_, _, _, _, _, _, _, onCompletion) = action else { return }
            onCompletion(.success(PaymentIntent.fake().copy(collectedPaymentMethod: .cardPresent(details: .fake()))))
        }
    }

    @Test func collectPayment_when_payment_success_sound_is_off_then_celebrates_without_sound() async throws {
        // Given
        paymentSettings.isPaymentSuccessSoundEnabled = false

        // When
        let result = await collectPayment()

        // Then
        _ = try result.get()
        #expect(celebration.celebrationWasCalled)
        #expect(celebration.playedSound == false)
    }

    @Test func collectPayment_when_payment_success_sound_is_on_then_celebrates_with_sound() async throws {
        // Given
        paymentSettings.isPaymentSuccessSoundEnabled = true

        // When
        let result = await collectPayment()

        // Then
        _ = try result.get()
        #expect(celebration.playedSound == true)
    }

    @Test func test_collectPayment_when_payment_is_invalidated_then_completes_with_paymentInvalidated() {
        // Given
        let sut = CardPresentPaymentInvalidatablePaymentOrchestrator()
        sut.invalidatePayment()
        var result: Result<CardPresentCapturedPaymentData, Error>?

        // When
        sut.collectPayment(for: .fake(),
                           orderTotal: 1,
                           paymentGatewayAccount: .fake(),
                           paymentMethodTypes: [.cardPresent],
                           stripeSmallestCurrencyUnitMultiplier: 100,
                           countryCode: .US,
                           terminalPaymentPreparationEnabled: false,
                           channel: .pos,
                           onPreparingReader: {},
                           onWaitingForInput: { _ in },
                           onCardInserted: {},
                           onProcessingMessage: {},
                           onDisplayMessage: { _ in },
                           onProcessingCompletion: { _ in },
                           onCompletion: { result = $0 })

        // Then
        #expect(isPaymentInvalidatedFailure(result))
    }

    @Test func test_retryPayment_when_payment_is_invalidated_from_a_nonisolated_context_then_completes_with_paymentInvalidated() async {
        // Given
        let sut = CardPresentPaymentInvalidatablePaymentOrchestrator()
        await Task.detached {
            sut.invalidatePayment()
        }.value
        var result: Result<CardPresentCapturedPaymentData, Error>?

        // When
        sut.retryPayment(for: .fake(), onCompletion: { result = $0 })

        // Then
        #expect(isPaymentInvalidatedFailure(result))
    }
}

private extension CardPresentPaymentInvalidatablePaymentOrchestratorTests {
    func collectPayment() async -> Result<CardPresentCapturedPaymentData, Error> {
        let sut = CardPresentPaymentInvalidatablePaymentOrchestrator(
            stores: stores,
            celebration: POSPaymentSuccessCelebration(paymentSettings: paymentSettings, celebration: celebration))

        return await withCheckedContinuation { continuation in
            sut.collectPayment(for: .fake(),
                               orderTotal: 1,
                               paymentGatewayAccount: .fake(),
                               paymentMethodTypes: [.cardPresent],
                               stripeSmallestCurrencyUnitMultiplier: 100,
                               countryCode: .US,
                               terminalPaymentPreparationEnabled: false,
                               channel: .pos,
                               onPreparingReader: {},
                               onWaitingForInput: { _ in },
                               onCardInserted: {},
                               onProcessingMessage: {},
                               onDisplayMessage: { _ in },
                               onProcessingCompletion: { _ in },
                               onCompletion: { continuation.resume(returning: $0) })
        }
    }
}

private func isPaymentInvalidatedFailure(_ result: Result<CardPresentCapturedPaymentData, Error>?) -> Bool {
    guard case .failure(let error) = result,
          case .paymentInvalidated = error as? CardPresentPaymentInvalidatablePaymentOrchestratorError else {
        return false
    }
    return true
}
