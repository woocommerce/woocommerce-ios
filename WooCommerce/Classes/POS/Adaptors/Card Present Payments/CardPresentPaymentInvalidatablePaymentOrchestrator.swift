import Foundation
import os
import Yosemite
import WooFoundation
import class PointOfSale.POSPaymentSuccessCelebration

@MainActor
final class CardPresentPaymentInvalidatablePaymentOrchestrator: PaymentCaptureOrchestrating {
    private let invalidated = OSAllocatedUnfairLock(initialState: false)
    private let paymentOrchestrator: PaymentCaptureOrchestrator

    /// POS celebrates through `POSPaymentSuccessCelebration`, which honors the payment success sound setting from POS settings.
    init(stores: StoresManager = ServiceLocator.stores,
         celebration: PaymentCaptureCelebrationProtocol = POSPaymentSuccessCelebration(),
         walletPresentationSuppression: WalletPresentationSuppressing? = nil) {
        self.paymentOrchestrator = PaymentCaptureOrchestrator(stores: stores,
                                                              celebration: celebration,
                                                              walletPresentationSuppression: walletPresentationSuppression)
    }

    /// Called from a task cancellation handler, which is nonisolated.
    nonisolated func invalidatePayment() {
        invalidated.withLock { $0 = true }
    }

    func collectPayment(for order: Order,
                        orderTotal: NSDecimalNumber,
                        paymentGatewayAccount: PaymentGatewayAccount,
                        readerType: CardReaderType,
                        paymentMethodTypes: [PaymentMethodType],
                        stripeSmallestCurrencyUnitMultiplier: Decimal,
                        countryCode: CountryCode,
                        terminalPaymentPreparationEnabled: Bool,
                        channel: PaymentChannel,
                        onPreparingReader: @escaping () -> Void,
                        onWaitingForInput: @escaping (CardReaderInput) -> Void,
                        onCardInserted: @escaping () -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onDisplayMessage: @escaping (String) -> Void,
                        onProcessingCompletion: @escaping (PaymentIntent) -> Void,
                        onCompletion: @escaping (Result<CardPresentCapturedPaymentData, any Error>) -> Void) {
        guard invalidated.withLock({ $0 }) == false else {
            return onCompletion(.failure(CardPresentPaymentInvalidatablePaymentOrchestratorError.paymentInvalidated))
        }
        paymentOrchestrator.collectPayment(for: order,
                                           orderTotal: orderTotal,
                                           paymentGatewayAccount: paymentGatewayAccount,
                                           readerType: readerType,
                                           paymentMethodTypes: paymentMethodTypes,
                                           stripeSmallestCurrencyUnitMultiplier: stripeSmallestCurrencyUnitMultiplier,
                                           countryCode: countryCode,
                                           terminalPaymentPreparationEnabled: terminalPaymentPreparationEnabled,
                                           channel: channel,
                                           onPreparingReader: onPreparingReader,
                                           onWaitingForInput: onWaitingForInput,
                                           onCardInserted: onCardInserted,
                                           onProcessingMessage: onProcessingMessage,
                                           onDisplayMessage: onDisplayMessage,
                                           onProcessingCompletion: onProcessingCompletion,
                                           onCompletion: onCompletion)
    }

    func retryPayment(for order: Order,
                      onCompletion: @escaping (Result<CardPresentCapturedPaymentData, any Error>) -> Void) {
        guard invalidated.withLock({ $0 }) == false else {
            return onCompletion(.failure(CardPresentPaymentInvalidatablePaymentOrchestratorError.paymentInvalidated))
        }
        paymentOrchestrator.retryPayment(for: order,
                                         onCompletion: onCompletion)
    }

    func cancelPayment(onCompletion: @escaping (Result<Void, any Error>) -> Void) {
        paymentOrchestrator.cancelPayment(onCompletion: onCompletion)
    }

    func presentBackendReceipt(for order: Order,
                               onCompletion: @escaping (Result<Receipt, any Error>) -> Void) {
        paymentOrchestrator.presentBackendReceipt(for: order, onCompletion: onCompletion)
    }
}

enum CardPresentPaymentInvalidatablePaymentOrchestratorError: Error {
    case paymentInvalidated
}
