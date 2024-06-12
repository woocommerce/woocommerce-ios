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

    @Published var showLoadPaymentsErrorAlert: Bool = false
    @Published private(set) var isLoadingPaymentMethods: Bool = true
    @Published private(set) var paymentMethods: [BlazePaymentMethod] = []

    var addPaymentWebViewModel: BlazeAddPaymentMethodWebViewModel? {
        BlazeAddPaymentMethodWebViewModel(siteID: siteID) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                let existingPaymentMethods = self.paymentMethods
                await self.reloadPaymentMethods()

                // Select the newly added payment method
                self.selectedPaymentMethodID = self.paymentMethods.first(where: { existingPaymentMethods.contains($0) == false })?.id
            }
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
         selectedPaymentMethodID: String? = nil,
         stores: StoresManager = ServiceLocator.stores,
         completion: @escaping Completion) {
        self.siteID = siteID
        self.originalSelectedPaymentMethodID = selectedPaymentMethodID
        self.selectedPaymentMethodID = selectedPaymentMethodID
        self.stores = stores
        self.onCompletion = completion
        self.defaultAccount = stores.sessionManager.defaultAccount
    }

    @MainActor
    func reloadPaymentMethods() async {
        isLoadingPaymentMethods = true
        paymentMethods = []
        do {
            paymentMethods = try await fetchPaymentInfo().paymentMethods
            selectedPaymentMethodID = originalSelectedPaymentMethodID ?? paymentMethods.first?.id
            isLoadingPaymentMethods = false
        } catch {
            DDLogError("⛔️ Error loading payment methods: \(error)")
            showLoadPaymentsErrorAlert = true
            isLoadingPaymentMethods = false
        }
    }

    func didSelectPaymentMethod(withID paymentMethodID: String?) {
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
        BlazePaymentInfo(paymentMethods: paymentMethods)
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
