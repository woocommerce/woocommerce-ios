import Foundation
import Yosemite

final class CardPresentPaymentInvalidatablePaymentOrchestrator: PaymentCaptureOrchestrating {
    private var invalidated: Bool = false
    private let paymentOrchestrator = PaymentCaptureOrchestrator()

    func invalidatePayment() {
        invalidated = true
    }

    func collectPayment(for order: Yosemite.Order, 
                        orderTotal: NSDecimalNumber,
                        paymentGatewayAccount: Yosemite.PaymentGatewayAccount,
                        paymentMethodTypes: [String],
                        stripeSmallestCurrencyUnitMultiplier: Decimal,
                        onPreparingReader: @escaping () -> Void,
                        onWaitingForInput: @escaping (Yosemite.CardReaderInput) -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onDisplayMessage: @escaping (String) -> Void,
                        onProcessingCompletion: @escaping (Yosemite.PaymentIntent) -> Void,
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

    func retryPayment(for order: Yosemite.Order, 
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

    func emailReceipt(for order: Yosemite.Order, 
                      params: Yosemite.CardPresentReceiptParameters,
                      onContent: @escaping (String) -> Void) {
        paymentOrchestrator.emailReceipt(for: order, params: params, onContent: onContent)
    }

    func saveReceipt(for order: Yosemite.Order, 
                     params: Yosemite.CardPresentReceiptParameters) {
        paymentOrchestrator.saveReceipt(for: order, params: params)
    }

    func presentBackendReceipt(for order: Yosemite.Order, 
                               onCompletion: @escaping (Result<Yosemite.Receipt, any Error>) -> Void) {
        paymentOrchestrator.presentBackendReceipt(for: order, onCompletion: onCompletion)
    }
}

enum CardPresentPaymentInvalidatablePaymentOrchestratorError: Error {
    case paymentInvalidated
}
