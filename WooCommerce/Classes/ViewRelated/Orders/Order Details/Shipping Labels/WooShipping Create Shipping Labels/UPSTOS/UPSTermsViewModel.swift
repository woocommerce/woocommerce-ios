import Foundation
import Yosemite

/// View model for `UPSTermsView`
final class UPSTermsViewModel: ObservableObject {
    @Published var isTOSAccepted = false
    @Published var isProhibitedItemsAccepted = false
    @Published var isTechnologyAgreementAccepted = false

    @Published private(set) var isConfirming = false

    var displayedOriginAddress: String {
        originAddress.formattedPostalAddress ?? ""
    }

    var shouldEnableConfirmButton: Bool {
        isTOSAccepted && isProhibitedItemsAccepted && isTechnologyAgreementAccepted
    }

    private let siteID: Int64
    private let originAddress: WooShippingAddress
    private let stores: StoresManager

    init(siteID: Int64,
         originAddress: WooShippingAddress,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.originAddress = originAddress
        self.stores = stores
    }

    @MainActor
    func confirmAcceptance() async throws -> Bool {
        isConfirming = true
        defer {
            isConfirming = false
        }
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(WooShippingAction.acceptUPSTermsOfService(siteID: siteID, originAddress: originAddress) { result in
                continuation.resume(with: result)
            })
        }
    }
}
