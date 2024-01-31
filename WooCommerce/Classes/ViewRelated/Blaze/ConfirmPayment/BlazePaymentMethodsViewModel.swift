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

    private let paymentInfo: BlazePaymentInfo?

    var paymentMethods: [BlazePaymentMethod] {
        paymentInfo?.savedPaymentMethods ?? []
    }

    var addPaymentWebViewModel: BlazeAddPaymentMethodWebViewModel? {
        guard let paymentInfo else {
            DDLogError("⛔️ No add payment info available to initiate Add payment method flow.")
            return nil
        }

        return BlazeAddPaymentMethodWebViewModel(siteID: siteID,
                                                 addPaymentMethodInfo: paymentInfo.addPaymentMethod) { [weak self] newPaymentMethodID in
            guard let self else { return }
            didSelectPaymentMethod(withID: newPaymentMethodID)
        }
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
        saveSelection()
    }
}

// MARK: - Private Helpers
//
private extension BlazePaymentMethodsViewModel {
    func saveSelection() {
        guard let selectedPaymentMethodID else {
            DDLogError("⛔️ No payment method selected in Blaze campaign creation")
            return
        }
        onCompletion(selectedPaymentMethodID)
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
