import Yosemite
import protocol WooFoundation.Analytics

/// View model for `BlazeAddPaymentMethodWebView`.
///
final class BlazeAddPaymentMethodWebViewModel: ObservableObject {
    typealias Completion = () -> Void
    private let analytics: Analytics
    private let onCompletion: Completion

    private let siteID: Int64

    @Published var notice: Notice?

    var addPaymentMethodURL: URL {
        WooConstants.URLs.addPaymentMethodWCShip.asURL()
    }

    var addPaymentSuccessURL: String {
        "me/purchases/payment-methods"
    }

    init(siteID: Int64,
         analytics: Analytics = ServiceLocator.analytics,
         completion: @escaping Completion) {
        self.siteID = siteID
        self.analytics = analytics
        self.onCompletion = completion
    }

    func onAppear() {
        analytics.track(event: .Blaze.Payment.addPaymentMethodWebViewDisplayed())
    }

    func didAddNewPaymentMethod() {
        notice = Notice(title: Localization.paymentMethodAddedNotice, feedbackType: .success)

        analytics.track(event: .Blaze.Payment.addPaymentMethodSuccess())
        onCompletion()
    }
}

private extension BlazeAddPaymentMethodWebViewModel {
    enum Localization {
        static let paymentMethodAddedNotice = NSLocalizedString(
            "blazeAddPaymentWebView.paymentMethodAddedNotice",
            value: "Payment method added",
            comment: "Notice that will be displayed after adding a new Blaze payment method"
        )
    }
}
