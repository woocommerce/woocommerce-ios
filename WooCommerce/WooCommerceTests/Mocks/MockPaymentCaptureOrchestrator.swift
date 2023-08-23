import Foundation
@testable import WooCommerce
import Yosemite

final class MockPaymentCaptureOrchestrator: PaymentCaptureOrchestrating {
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
                        onWaitingForInput: @escaping (Yosemite.CardReaderInput) -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onDisplayMessage: @escaping (String) -> Void,
                        onProcessingCompletion: @escaping (Yosemite.PaymentIntent) -> Void,
                        onCompletion: @escaping (Result<WooCommerce.CardPresentCapturedPaymentData, Error>) -> Void) {
        spyDidCallCollectPayment = true
        spyCollectPaymentOrder = order
        spyCollectPaymentGatewayAccount = paymentGatewayAccount
        spyCollectPaymentMethodTypes = paymentMethodTypes
        spyCollectPaymentStripeSmallestCurrencyUnitMultiplier = stripeSmallestCurrencyUnitMultiplier
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
}
