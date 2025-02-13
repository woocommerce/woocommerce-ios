import Foundation
import Yosemite
import protocol WooFoundation.Analytics

protocol CollectOrderPaymentAnalyticsTracking {
    var connectedReaderModel: String? { get }

    func preflightResultReceived(_ result: CardReaderPreflightResult?)

    func trackProcessingCompletion(intent: PaymentIntent)

    func trackSuccessfulPayment(capturedPaymentData: CardPresentCapturedPaymentData)

    func trackPaymentFailure(with error: Error)

    func trackPaymentCancelation(cancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource)

    func trackEmailTapped()

    func trackReceiptPrintTapped()

    func trackReceiptPrintSuccess()

    func trackReceiptPrintCanceled()

    func trackReceiptPrintFailed(error: Error)
    
    func trackCustomerInteractionStarted()
}

final class POSCollectOrderPaymentAnalytics: CollectOrderPaymentAnalyticsTracking {
    var connectedReaderModel: String?

    private var customerInteractionStarted: Double = 0

    func preflightResultReceived(_ result: CardReaderPreflightResult?) { }
    func trackProcessingCompletion(intent: Yosemite.PaymentIntent) { }

    func trackSuccessfulPayment(capturedPaymentData: CardPresentCapturedPaymentData) {
        let customerInteractionFinished = Date().timeIntervalSince1970 - customerInteractionStarted
        debugPrint("end at \(customerInteractionFinished)")
        ServiceLocator.analytics.track(event: WooAnalyticsEvent.PointOfSale.cardPresentCollectPaymentSuccess(millisecondsSinceCustomerIteractionStated: customerInteractionFinished))
    }

    func trackPaymentFailure(with error: any Error) { }
    func trackPaymentCancelation(cancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource) { }
    func trackEmailTapped() { }
    func trackReceiptPrintTapped() { }
    func trackReceiptPrintSuccess() { }
    func trackReceiptPrintCanceled() { }
    func trackReceiptPrintFailed(error: any Error) { }

    func trackCustomerInteractionStarted() {
        customerInteractionStarted = Date().timeIntervalSince1970
        debugPrint("started at \(customerInteractionStarted)")
    }
}

// Protocol conformance. These events are not needed for IPP, only for POS.
extension CollectOrderPaymentAnalytics {
    func trackCustomerInteractionStarted() { }
}

final class CollectOrderPaymentAnalytics: CollectOrderPaymentAnalyticsTracking {

    private let siteID: Int64
    private let analytics: Analytics
    private let configuration: CardPresentPaymentsConfiguration
    private let orderDurationRecorder: OrderDurationRecorderProtocol
    private var connectedReader: CardReader?
    private var paymentGatewayAccount: PaymentGatewayAccount?

    var connectedReaderModel: String? {
        connectedReader?.readerType.model
    }

    init(siteID: Int64,
         analytics: Analytics = ServiceLocator.analytics,
         configuration: CardPresentPaymentsConfiguration,
         orderDurationRecorder: OrderDurationRecorderProtocol = OrderDurationRecorder.shared,
         connectedReader: CardReader? = nil,
         paymentGatewayAccount: PaymentGatewayAccount? = nil) {
        self.siteID = siteID
        self.analytics = analytics
        self.configuration = configuration
        self.orderDurationRecorder = orderDurationRecorder
        self.connectedReader = connectedReader
        self.paymentGatewayAccount = paymentGatewayAccount
    }

    func preflightResultReceived(_ result: CardReaderPreflightResult?) {
        switch result {
        case .completed(let connectedReader, let paymentGatewayAccount):
            self.connectedReader = connectedReader
            self.paymentGatewayAccount = paymentGatewayAccount
        case .canceled(_, let paymentGatewayAccount):
            self.connectedReader = nil
            self.paymentGatewayAccount = paymentGatewayAccount
        case .none:
            break
        }
    }

    func trackProcessingCompletion(intent: PaymentIntent) {
        guard let paymentMethod = intent.paymentMethod() else {
            return
        }
        switch paymentMethod {
        case .interacPresent:
            analytics.track(event: .InPersonPayments
                .collectInteracPaymentSuccess(gatewayID: paymentGatewayAccount?.gatewayID,
                                              countryCode: configuration.countryCode,
                                              cardReaderModel: connectedReaderModel,
                                              siteID: siteID))
        default:
            return
        }
    }

    func trackSuccessfulPayment(capturedPaymentData: CardPresentCapturedPaymentData) {
        analytics.track(event: WooAnalyticsEvent.InPersonPayments
            .collectPaymentSuccess(forGatewayID: paymentGatewayAccount?.gatewayID,
                                   countryCode: configuration.countryCode,
                                   paymentMethod: capturedPaymentData.paymentMethod,
                                   cardReaderModel: connectedReaderModel,
                                   millisecondsSinceOrderAddNew: try? orderDurationRecorder.millisecondsSinceOrderAddNew(),
                                   millisecondsSinceCardPaymentStarted: try? orderDurationRecorder.millisecondsSinceCardPaymentStarted(),
                                   siteID: siteID))
        orderDurationRecorder.reset()
    }

    func trackPaymentFailure(with error: Error) {
        analytics.track(event: WooAnalyticsEvent.InPersonPayments.collectPaymentFailed(forGatewayID: paymentGatewayAccount?.gatewayID,
                                                                                       error: error,
                                                                                       countryCode: configuration.countryCode,
                                                                                       cardReaderModel: connectedReader?.readerType.model,
                                                                                       siteID: siteID))
    }

    func trackPaymentCancelation(cancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource) {
        analytics.track(event: WooAnalyticsEvent.InPersonPayments.collectPaymentCanceled(forGatewayID: paymentGatewayAccount?.gatewayID,
                                                                                         countryCode: configuration.countryCode,
                                                                                         cardReaderModel: connectedReaderModel,
                                                                                         cancellationSource: cancelationSource,
                                                                                         siteID: siteID))
    }

    func trackEmailTapped() {
        analytics.track(event: .InPersonPayments
            .receiptEmailTapped(countryCode: configuration.countryCode,
                                cardReaderModel: connectedReader?.readerType.model ?? "",
                                source: .local))
    }

    func trackReceiptPrintTapped() {
        analytics.track(event: .InPersonPayments.receiptPrintTapped(countryCode: configuration.countryCode,
                                                                    cardReaderModel: connectedReaderModel,
                                                                    source: .local))
    }

    func trackReceiptPrintSuccess() {
        analytics.track(event: .InPersonPayments.receiptPrintSuccess(countryCode: configuration.countryCode,
                                                                     cardReaderModel: connectedReaderModel,
                                                                     source: .local))
    }

    func trackReceiptPrintCanceled() {
        analytics.track(event: .InPersonPayments.receiptPrintCanceled(countryCode: configuration.countryCode,
                                                                      cardReaderModel: connectedReaderModel,
                                                                      source: .local))
    }

    func trackReceiptPrintFailed(error: Error) {
        analytics.track(event: .InPersonPayments.receiptPrintFailed(error: error,
                                                                    countryCode: configuration.countryCode,
                                                                    cardReaderModel: connectedReaderModel,
                                                                    source: .local))
    }
}
