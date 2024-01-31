import Yosemite

/// View model for `BlazeAddPaymentMethodWebView`.
///
final class BlazeAddPaymentMethodWebViewModel: ObservableObject {
    typealias Completion = (_ newPaymentMethodID: String) -> Void
    private let analytics: Analytics
    private let onCompletion: Completion

    private let siteID: Int64
    private let addPaymentMethodInfo: BlazeAddPaymentInfo

    @Published var notice: Notice?

    var addPaymentMethodURL: URL? {
        URL(string: addPaymentMethodInfo.formUrl)
    }

    var addPaymentSuccessURL: String {
        addPaymentMethodInfo.successUrl
    }

    init(siteID: Int64,
         addPaymentMethodInfo: BlazeAddPaymentInfo,
         analytics: Analytics = ServiceLocator.analytics,
         completion: @escaping Completion) {
        self.siteID = siteID
        self.addPaymentMethodInfo = addPaymentMethodInfo
        self.analytics = analytics
        self.onCompletion = completion
    }

    func onAppear() {
        analytics.track(event: .Blaze.Payment.addPaymentMethodWebViewDisplayed())
    }

    func didAddNewPaymentMethod(successURL: URL?) {
        notice = Notice(title: Localization.paymentMethodAddedNotice, feedbackType: .success)

        guard let successURL,
              let urlComponents = URLComponents(url: successURL, resolvingAgainstBaseURL: true),
              let newPaymentMethodID = urlComponents.queryItems?.first(where: { $0.name == addPaymentMethodInfo.idUrlParameter })?.value else {
            DDLogError("⛔️ Failed to get newly added payment method ID from Blaze Add payment web view.")
            return
        }

        analytics.track(event: .Blaze.Payment.addPaymentMethodSuccess())
        onCompletion(newPaymentMethodID)
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
