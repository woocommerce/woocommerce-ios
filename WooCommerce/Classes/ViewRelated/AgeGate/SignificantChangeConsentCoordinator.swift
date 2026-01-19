import Foundation
import UIKit

final class SignificantChangeConsentCoordinator {
    private let consentProvider: SignificantChangeConsentProviding
    private let consentStore: SignificantChangeConsentStoring

    init(
        consentProvider: SignificantChangeConsentProviding = PermissionKitSignificantChangeConsentProvider(),
        consentStore: SignificantChangeConsentStoring = UserDefaultsSignificantChangeConsentStore()
    ) {
        self.consentProvider = consentProvider
        self.consentStore = consentStore
    }

    func checkConsentIfNeeded(
        in viewController: UIViewController,
        ageRatingChange: AgeRatingChangeCheckResult?,
        manualChangeIdentifier: SignificantChangeIdentifier? = nil
    ) async -> SignificantChangeConsentOutcome {
        let changeIdentifier: SignificantChangeIdentifier? = {
            if let manualChangeIdentifier { return manualChangeIdentifier }
            guard let ageRatingChange else { return nil }
            switch ageRatingChange {
            case let .ageRatingChanged(_, ratingCode):
                return .ageRatingChange(ratingCode: ratingCode)
            }
        }()

        guard let changeIdentifier else {
            return .granted
        }

        if let status = consentStore.status(for: changeIdentifier) {
            return status == .granted ? .granted : .denied
        }

        let outcome = await consentProvider.requestConsent(
            in: viewController,
            significantAppUpdateDescription: {
                switch changeIdentifier {
                case .ageRatingChange:
                    return String(
                        format: Localization.ageRatingChangeRequestDescriptionFormat,
                        arguments: changeIdentifier.updateDescriptionFormatArguments
                    )
                case .manual:
                    return String(
                        format: Localization.manualChangeRequestDescriptionFormat,
                        arguments: changeIdentifier.updateDescriptionFormatArguments
                    )
                }
            }()
        )
        switch outcome {
        case .granted:
            consentStore.setStatus(.granted, for: changeIdentifier)
        case .denied:
            consentStore.setStatus(.denied, for: changeIdentifier)
        case .notAvailable, .unknown:
            break
        }

        return outcome
    }
}

private extension SignificantChangeConsentCoordinator {
    enum Localization {
        static let ageRatingChangeRequestDescriptionFormat = NSLocalizedString(
            "significantChangeConsent.ageRatingChange.description",
            value: "App age rating changed to %1$d.",
            comment: "PermissionKit description shown when the app age rating changes." +
            "ratingCode: %1$d is the new rating code."
        )

        static let manualChangeRequestDescriptionFormat = NSLocalizedString(
            "significantChangeConsent.manual.description",
            value: "Significant app update: %1$@.",
            comment: "PermissionKit description shown for a manual significant change." +
            "manualChangeID: %1$@ is a short description."
        )
    }
}
