import Yosemite

/// View model for `BlazeAddPaymentMethodWebView`.
///
final class BlazeAddPaymentMethodWebViewModel: ObservableObject {
    typealias Completion = (_ newPaymentMethodID: String) -> Void
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
         completion: @escaping Completion) {
        self.siteID = siteID
        self.addPaymentMethodInfo = addPaymentMethodInfo
        self.onCompletion = completion
    }

    func didAddNewPaymentMethod(successURL: URL?) {
        guard let successURL,
              let urlComponents = URLComponents(url: successURL, resolvingAgainstBaseURL: true),
              let newPaymentMethodID = urlComponents.queryItems?.first(where: { $0.name == addPaymentMethodInfo.idUrlParameter })?.value else {
            DDLogError("⛔️ Failed to get newly added payment method ID from Blaze Add payment web view.")
            return
        }

        onCompletion(newPaymentMethodID)
    }
}
