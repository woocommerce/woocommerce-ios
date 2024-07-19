import Foundation
import Yosemite

final class CardPresentPaymentInvalidatablePaymentOrchestrator: PaymentCaptureOrchestrating {
    private var invalidated: Bool = false
    private let paymentOrchestrator = PaymentCaptureOrchestrator()

    func invalidatePayment() {
        invalidated = true
    }

    func collectPayment(for order: Order,
                        orderTotal: NSDecimalNumber,
                        paymentGatewayAccount: PaymentGatewayAccount,
                        paymentMethodTypes: [String],
                        stripeSmallestCurrencyUnitMultiplier: Decimal,
                        onPreparingReader: @escaping () -> Void,
                        onWaitingForInput: @escaping (CardReaderInput) -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onDisplayMessage: @escaping (String) -> Void,
                        onProcessingCompletion: @escaping (PaymentIntent) -> Void,
                        onCompletion: @escaping (Result<CardPresentCapturedPaymentData, any Error>) -> Void) {
        guard invalidated == false else {
            return onCompletion(.failure(CardPresentPaymentInvalidatablePaymentOrchestratorError.paymentInvalidated))
        }
        paymentOrchestrator.collectPayment(for: order,
                                           orderTotal: orderTotal,
                                           paymentGatewayAccount: paymentGatewayAccount,
                                           paymentMethodTypes: paymentMethodTypes,
                                           stripeSmallestCurrencyUnitMultiplier: stripeSmallestCurrencyUnitMultiplier,
                                           onPreparingReader: onPreparingReader,
                                           onWaitingForInput: onWaitingForInput,
                                           onProcessingMessage: onProcessingMessage,
                                           onDisplayMessage: onDisplayMessage,
                                           onProcessingCompletion: onProcessingCompletion,
                                           onCompletion: onCompletion)
    }

    func retryPayment(for order: Order,
                      onCompletion: @escaping (Result<CardPresentCapturedPaymentData, any Error>) -> Void) {
        guard invalidated == false else {
            return onCompletion(.failure(CardPresentPaymentInvalidatablePaymentOrchestratorError.paymentInvalidated))
        }
        paymentOrchestrator.retryPayment(for: order,
                                         onCompletion: onCompletion)
    }

    func cancelPayment(onCompletion: @escaping (Result<Void, any Error>) -> Void) {
        paymentOrchestrator.cancelPayment(onCompletion: onCompletion)
    }

    func emailReceipt(for order: Order,
                      params: CardPresentReceiptParameters,
                      onContent: @escaping (String) -> Void) {
        paymentOrchestrator.emailReceipt(for: order, params: params, onContent: onContent)
    }

    func saveReceipt(for order: Order,
                     params: CardPresentReceiptParameters) {
        paymentOrchestrator.saveReceipt(for: order, params: params)
    }

    func presentBackendReceipt(for order: Order,
                               onCompletion: @escaping (Result<Receipt, any Error>) -> Void) {
        paymentOrchestrator.presentBackendReceipt(for: order, onCompletion: onCompletion)
    }
}

enum CardPresentPaymentInvalidatablePaymentOrchestratorError: Error {
    case paymentInvalidated
}
