import Foundation
@testable import WooCommerce
import Yosemite

final class MockPaymentCaptureOrchestrator: PaymentCaptureOrchestrating {
    var mockCollectPaymentHandler: ((_ onPreparingReader: () -> Void,
                                     _ onWaitingForInput: (Yosemite.CardReaderInput) -> Void,
                                     _ onProcessingMessage: () -> Void,
                                     _ onDisplayMessage: (String) -> Void,
                                     _ onProcessingCompletion: (Yosemite.PaymentIntent) -> Void,
                                     _ onCompletion: (Result<CardPresentCapturedPaymentData, Error>) -> Void) -> Void)? = nil

    var spyDidCallCollectPayment = false
    var spyCollectPaymentOrder: Order? = nil
    var spyCollectPaymentGatewayAccount: PaymentGatewayAccount? = nil
    var spyCollectPaymentMethodTypes: [String]? = nil
    var spyCollectPaymentStripeSmallestCurrencyUnitMultiplier: Decimal? = nil
    func collectPayment(for order: Order,
                        orderTotal: NSDecimalNumber,
                        paymentGatewayAccount: PaymentGatewayAccount,
                        paymentMethodTypes: [String],
                        stripeSmallestCurrencyUnitMultiplier: Decimal,
                        onPreparingReader: () -> Void,
                        onWaitingForInput: @escaping (CardReaderInput) -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onDisplayMessage: @escaping (String) -> Void,
                        onProcessingCompletion: @escaping (PaymentIntent) -> Void,
                        onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> Void) {
        spyDidCallCollectPayment = true
        spyCollectPaymentOrder = order
        spyCollectPaymentGatewayAccount = paymentGatewayAccount
        spyCollectPaymentMethodTypes = paymentMethodTypes
        spyCollectPaymentStripeSmallestCurrencyUnitMultiplier = stripeSmallestCurrencyUnitMultiplier

        mockCollectPaymentHandler?(onPreparingReader,
                                   onWaitingForInput,
                                   onProcessingMessage,
                                   onDisplayMessage,
                                   onProcessingCompletion,
                                   onCompletion)
    }

    var spyDidCallRetryPayment = false
    func retryPayment(for order: Yosemite.Order,
                      onCompletion: @escaping (Result<WooCommerce.CardPresentCapturedPaymentData, Error>) -> Void) {
        spyDidCallRetryPayment = true
    }

    var spyDidCallCancelPayment = false
    func cancelPayment(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        spyDidCallCancelPayment = true
    }

    var spyDidCallEmailReceipt = false
    var spyEmailReceiptOrder: Order? = nil
    var spyEmailReceiptParams: CardPresentReceiptParameters? = nil
    func emailReceipt(for order: Order,
                      params: CardPresentReceiptParameters,
                      onContent: @escaping (String) -> Void) {
        spyDidCallEmailReceipt = true
        spyEmailReceiptOrder = order
        spyEmailReceiptParams = params
    }

    var spyDidCallSaveReceipt = false
    var spySaveReceiptOrder: Order? = nil
    var spySaveReceiptParams: CardPresentReceiptParameters? = nil
    func saveReceipt(for order: Order,
                     params: CardPresentReceiptParameters) {
        spyDidCallSaveReceipt = true
        spySaveReceiptOrder = order
        spySaveReceiptParams = params
    }

    func presentBackendReceipt(for order: Yosemite.Order, onCompletion: @escaping (Result<Yosemite.Receipt, Error>) -> Void) {
        // no implemented
    }
}
