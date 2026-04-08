import Foundation
import Yosemite

/// View model for UPS Terms and Conditions acceptance.
final class UPSTermsViewModel: ObservableObject, CarrierTermsViewModel {
    @Published var isTOSAccepted = false
    @Published var isProhibitedItemsAccepted = false
    @Published var isTechnologyAgreementAccepted = false

    @Published private(set) var isConfirming = false

    let title: String = NSLocalizedString(
        "upsTermsView.title",
        value: "UPS\u{00AE} Terms and Conditions",
        comment: "Title of the UPS Terms and Conditions view"
    )

    let message: String = NSLocalizedString(
        "upsTermsView.message",
        value: "To start shipping from this address with UPS\u{00AE}, " +
        "we need you to agree to the following terms and conditions:",
        comment: "Message on the UPS Terms and Conditions view"
    )

    var displayedOriginAddress: String? {
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

// MARK: - Checkbox Configuration
extension UPSTermsViewModel {
    enum Links {
        static let termsOfService = "https://www.ups.com/assets/resources/webcontent/en_US/ups_dap_supplemental_tc.pdf"
        static let prohibitedItems = "https://www.ups.com/us/en/support/shipping-support/shipping-special-care-regulated-items/prohibited-items.page"
        static let techAgreement = "https://www.ups.com/assets/resources/webcontent/en_US/UTA.pdf"
    }

    enum Localization {
        static let checkbox1 = NSLocalizedString(
            "upsTermsView.checkbox1",
            value: "I agree to the %1$@.",
            comment: "The first checkbox on the UPS Terms and Conditions view. " +
            "The placeholder is a link to the UPS Terms of Service. " +
            "Reads as: 'I agree to the UPS\u{00AE} Terms of Service.'"
        )
        static let checkbox2 = NSLocalizedString(
            "upsTermsView.checkbox2",
            value: "I will not ship any %1$@ that UPS\u{00AE} disallows, " +
            "nor any regulated items without the necessary permissions.",
            comment: "The second checkbox on the UPS Terms and Conditions view. " +
            "The placeholder is a link to the list of prohibited items. " +
            "Reads as: 'I will not ship any Prohibited Items that UPS\u{00AE} disallows, " +
            "nor any regulated items without the necessary permissions.'"
        )
        static let checkbox3 = NSLocalizedString(
            "upsTermsView.checkbox3",
            value: "I also agree to the %1$@.",
            comment: "The third checkbox on the UPS Terms and Conditions view. " +
            "The placeholder is a link to the UPS Technology Agreement. " +
            "Reads as: 'I also agree to the UPS\u{00AE} Technology Agreement.'"
        )
        static let termsOfService = NSLocalizedString(
            "upsTermsView.termsOfService",
            value: "UPS\u{00AE} Terms of Service",
            comment: "Link to the terms of service on the UPS Terms and Conditions view"
        )
        static let prohibitedItems = NSLocalizedString(
            "upsTermsView.prohibitedItems",
            value: "Prohibited Items",
            comment: "Link to the prohibited items on the UPS Terms and Conditions view"
        )
        static let technologyAgreement = NSLocalizedString(
            "upsTermsView.technologyAgreement",
            value: "UPS\u{00AE} Technology Agreement",
            comment: "Link to the technology agreement on the UPS Terms and Conditions view"
        )
    }
}
