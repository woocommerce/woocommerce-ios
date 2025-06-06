import Foundation
import Yosemite

/// View model for `UPSTermsView`
final class UPSTermsViewModel: ObservableObject {
    @Published var isTOSAccepted = false
    @Published var isProhibitedItemsAccepted = false
    @Published var isTechnologyAgreementAccepted = false

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
}
