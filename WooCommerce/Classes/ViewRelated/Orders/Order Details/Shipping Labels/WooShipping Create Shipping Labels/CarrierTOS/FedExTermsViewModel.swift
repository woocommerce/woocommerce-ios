import Foundation
import Yosemite

/// View model for FedEx Terms of Service acceptance.
final class FedExTermsViewModel: ObservableObject, CarrierTermsViewModel {
    @Published var isTOSAccepted = false

    @Published private(set) var isConfirming = false

    let title: String = NSLocalizedString(
        "fedExTermsView.title",
        value: "FedEx Terms of Service",
        comment: "Title of the FedEx Terms of Service view"
    )

    let message: String = NSLocalizedString(
        "fedExTermsView.message",
        value: "To purchase FedEx shipping labels, you need to agree to the following terms:",
        comment: "Message on the FedEx Terms of Service view"
    )

    var displayedOriginAddress: String? {
        nil
    }

    var shouldEnableConfirmButton: Bool {
        isTOSAccepted
    }

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    @MainActor
    func confirmAcceptance() async throws -> Bool {
        isConfirming = true
        defer {
            isConfirming = false
        }
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(WooShippingAction.acceptFedExTermsOfService(siteID: siteID) { result in
                continuation.resume(with: result)
            })
        }
    }
}

// MARK: - Checkbox Configuration
extension FedExTermsViewModel {
    enum Links {
        static let termsOfService = "https://wordpress.com/tos/"
    }

    enum Localization {
        static let checkbox = NSLocalizedString(
            "fedExTermsView.checkbox",
            value: "I agree to the %1$@.",
            comment: "The checkbox on the FedEx Terms of Service view. " +
            "The placeholder is a link to the FedEx Terms of Service. " +
            "Reads as: 'I agree to the FedEx Terms of Service.'"
        )
        static let termsOfService = NSLocalizedString(
            "fedExTermsView.termsOfService",
            value: "FedEx Terms of Service",
            comment: "Link to the terms of service on the FedEx Terms of Service view"
        )
    }
}
