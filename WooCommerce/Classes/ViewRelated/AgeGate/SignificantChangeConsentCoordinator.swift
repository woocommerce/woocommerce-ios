import Foundation
import UIKit

final class SignificantChangeConsentCoordinator {
    private let consentProvider: SignificantChangeConsentProviding

    init(
        consentProvider: SignificantChangeConsentProviding = PermissionKitSignificantChangeConsentProvider()
    ) {
        self.consentProvider = consentProvider
    }

    func checkConsentIfNeeded(
        in viewController: UIViewController,
        isMinor: Bool,
        significantAppChangeApprovalRequired: Bool,
        isAgeRatingChangeDetected: Bool,
        significantAppUpdateDescription: String
    ) async -> SignificantChangeConsentOutcome {
        guard
            isMinor,
            significantAppChangeApprovalRequired,
            isAgeRatingChangeDetected
        else {
            return .granted
        }

        return await consentProvider.requestConsent(
            in: viewController,
            significantAppUpdateDescription: significantAppUpdateDescription
        )
    }
}
