import Foundation
@testable import WooCommerce
import Yosemite
import WooFoundation

final class MockPaymentCaptureOrchestrator: PaymentCaptureOrchestrating {
    var mockCollectPaymentHandler: ((_ onPreparingReader: () -> Void,
                                     _ onWaitingForInput: (Yosemite.CardReaderInput) -> Void,
                                     _ onProcessingMessage: () -> Void,
                                     _ onCardInserted: () -> Void,
                                     _ onDisplayMessage: (String) -> Void,
                                     _ onProcessingCompletion: (Yosemite.PaymentIntent) -> Void,
                                     _ onCompletion: (Result<CardPresentCapturedPaymentData, Error>) -> Void) -> Void)? = nil

    var spyDidCallCollectPayment = false
    var spyCollectPaymentOrder: Order? = nil
    var spyCollectPaymentGatewayAccount: PaymentGatewayAccount? = nil
    var spyCollectPaymentMethodTypes: [PaymentMethodType]? = nil
    var spyCollectPaymentStripeSmallestCurrencyUnitMultiplier: Decimal? = nil
    var spyCollectPaymentCountryCode: CountryCode? = nil
    var spyTerminalPaymentPreparationEnabled: Bool?
    var spyChannel: PaymentChannel? = nil
    func collectPayment(for order: Order,
                        orderTotal: NSDecimalNumber,
                        paymentGatewayAccount: PaymentGatewayAccount,
                        paymentMethodTypes: [PaymentMethodType],
                        stripeSmallestCurrencyUnitMultiplier: Decimal,
                        countryCode: CountryCode,
                        terminalPaymentPreparationEnabled: Bool,
                        channel: PaymentChannel,
                        onPreparingReader: () -> Void,
                        onWaitingForInput: @escaping (CardReaderInput) -> Void,
                        onCardInserted: @escaping () -> Void,
                        onProcessingMessage: @escaping () -> Void,
                        onDisplayMessage: @escaping (String) -> Void,
                        onProcessingCompletion: @escaping (PaymentIntent) -> Void,
                        onCompletion: @escaping (Result<CardPresentCapturedPaymentData, Error>) -> Void) {
        spyDidCallCollectPayment = true
        spyCollectPaymentOrder = order
        spyCollectPaymentGatewayAccount = paymentGatewayAccount
        spyCollectPaymentMethodTypes = paymentMethodTypes
        spyCollectPaymentStripeSmallestCurrencyUnitMultiplier = stripeSmallestCurrencyUnitMultiplier
        spyCollectPaymentCountryCode = countryCode
        spyTerminalPaymentPreparationEnabled = terminalPaymentPreparationEnabled
        spyChannel = channel

        mockCollectPaymentHandler?(onPreparingReader,
                                   onWaitingForInput,
                                   onProcessingMessage,
                                   onCardInserted,
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
    var mockCancelPaymentResult: Result<Void, Error> = .success(())
    var mockCancelPaymentHandler: ((@escaping (Result<Void, Error>) -> Void) -> Void)?
    func cancelPayment(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        spyDidCallCancelPayment = true
        if let mockCancelPaymentHandler {
            mockCancelPaymentHandler(onCompletion)
        } else {
            onCompletion(mockCancelPaymentResult)
        }
    }

    func presentBackendReceipt(for order: Yosemite.Order, onCompletion: @escaping (Result<Yosemite.Receipt, Error>) -> Void) {
        // no implemented
    }
}
