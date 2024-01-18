import Yosemite

/// View model for `BlazePaymentMethodsView`.
///
final class BlazePaymentMethodsViewModel: ObservableObject {
    typealias Completion = (_ selectedPaymentMethodID: String) -> Void
    private let onCompletion: Completion

    private let siteID: Int64
    private let originalSelectedPaymentMethodID: String?
    private let stores: StoresManager
    private let defaultAccount: Account?

    @Published private var paymentInfo: BlazePaymentInfo?
    @Published private(set) var isFetchingPaymentInfo = false
    @Published var shouldDisplayPaymentErrorAlert = false

    var paymentMethods: [BlazePaymentMethod] {
        paymentInfo?.savedPaymentMethods ?? []
    }

    @Published private(set) var selectedPaymentMethodID: String?

    var userEmail: String {
        defaultAccount?.email ?? ""
    }

    var WPCOMUsername: String {
        defaultAccount?.username ?? ""
    }

    var WPCOMEmail: String {
        defaultAccount?.email ?? ""
    }

    var addPaymentMethodURL: URL? {
        guard let paymentInfo else {
            return nil
        }
        return URL(string: paymentInfo.addPaymentMethod.formUrl)
    }

    var addPaymentSuccessURL: String? {
        paymentInfo?.addPaymentMethod.successUrl
    }

    var isDoneButtonEnabled: Bool {
        guard !isFetchingPaymentInfo else {
            return false
        }
        return selectedPaymentMethodID != originalSelectedPaymentMethodID
    }

    init(siteID: Int64,
         paymentInfo: BlazePaymentInfo,
         selectedPaymentMethodID: String? = nil,
         stores: StoresManager = ServiceLocator.stores,
         completion: @escaping Completion) {
        self.siteID = siteID
        self.paymentInfo = paymentInfo
        self.originalSelectedPaymentMethodID = selectedPaymentMethodID
        self.selectedPaymentMethodID = selectedPaymentMethodID ?? paymentInfo.savedPaymentMethods.first?.id
        self.stores = stores
        self.onCompletion = completion
        self.defaultAccount = stores.sessionManager.defaultAccount
    }

    func didSelectPaymentMethod(withID paymentMethodID: String) {
        selectedPaymentMethodID = paymentMethodID
    }

    @MainActor
    func syncPaymentInfo() async {
        shouldDisplayPaymentErrorAlert = false
        isFetchingPaymentInfo = true
        do {
            paymentInfo = try await fetchPaymentInfo()
        } catch {
            DDLogError("⛔️ Error fetching payment info for Blaze campaign creation: \(error)")
            shouldDisplayPaymentErrorAlert = true
        }
        isFetchingPaymentInfo = false
    }

    func saveSelection() {
        guard let selectedPaymentMethodID else {
            DDLogError("⛔️ No payment method selected in Blaze campaign creation")
            return
        }
        onCompletion(selectedPaymentMethodID)
    }
}

// MARK: - API Requests
//
private extension BlazePaymentMethodsViewModel {
    @MainActor
    func fetchPaymentInfo() async throws -> BlazePaymentInfo {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(BlazeAction.fetchPaymentInfo(siteID: siteID, onCompletion: { result in
                continuation.resume(with: result)
            }))
        }
    }
}

// MARK: - Methods for rendering a SwiftUI Preview
//
extension BlazePaymentMethodsViewModel {
    static func samplePaymentInfo(paymentMethods: [BlazePaymentMethod] = samplePaymentMethods()) -> BlazePaymentInfo {
        BlazePaymentInfo(savedPaymentMethods: paymentMethods, addPaymentMethod: BlazeAddPaymentInfo(formUrl: "https://example.com/blaze-pm-add",
                                                                                                            successUrl: "https://example.com/blaze-pm-success",
                                                                                                            idUrlParameter: "pmid"))
    }

    static func samplePaymentMethods() -> [BlazePaymentMethod] {

        let paymentMethod1 = BlazePaymentMethod(id: "payment-method-1",
                                                rawType: "credit_card",
                                                name: "Visa **** 4253",
                                                info: BlazePaymentMethod.Info(lastDigits: "4253",
                                                                              expiring: BlazePaymentMethod.ExpiringInfo(year: 2029,
                                                                                                                        month: 9),
                                                                              type: "Visa",
                                                                              nickname: "Marie",
                                                                              cardholderName: "Marie Claire"))

        let paymentMethod2 = BlazePaymentMethod(id: "payment-method-2",
                                                rawType: "credit_card",
                                                name: "Visa **** 4342",
                                                info: BlazePaymentMethod.Info(lastDigits: "4342",
                                                                              expiring: BlazePaymentMethod.ExpiringInfo(year: 2026,
                                                                                                                        month: 5),
                                                                              type: "Visa",
                                                                              nickname: "Marie",
                                                                              cardholderName: "Marie Claire"))

        return [paymentMethod1, paymentMethod2]
    }
}
