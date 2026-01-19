import UIKit
import Experiments

enum AppAccessDescision: Equatable {
    case allow
    case denyAndLogout
}

protocol AgeRangeVerificationCoordinatorProtocol {
    func triggerAgeVerificationIfNeeded(
        hostingWindow: UIWindow,
        onResult: @escaping (AppAccessDescision, AgeRangeVerificationResult) -> Void
    )
}

extension AgeRangeVerificationCoordinator {
    enum Constants {
        static let minimumTOSRequiredAge = 13
    }
}

final class AgeRangeVerificationCoordinator: AgeRangeVerificationCoordinatorProtocol {
    private let featureFlagService: FeatureFlagService
    private let ageRangeVerificationService: AgeRangeVerificationServiceProtocol
    private let significantChangeConsentCoordinator: SignificantChangeConsentCoordinator
    private let ageRatingChangeDetector: AgeRatingChangeDetecting

    init(
        featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
        ageRangeVerificationService: AgeRangeVerificationServiceProtocol = ServiceLocator.ageRangeVerificationService,
        significantChangeConsentCoordinator: SignificantChangeConsentCoordinator = SignificantChangeConsentCoordinator(),
        ageRatingChangeDetector: AgeRatingChangeDetecting = NoOpAgeRatingChangeDetector()
    ) {
        self.featureFlagService = featureFlagService
        self.ageRangeVerificationService = ageRangeVerificationService
        self.significantChangeConsentCoordinator = significantChangeConsentCoordinator
        self.ageRatingChangeDetector = ageRatingChangeDetector
    }

    /// Triggers the age range verification flow.
    /// Handles "blocking UI" presenting in case of ineligible age and performs a logout.
    /// - Parameters:
    ///   - hostingWindow: The window that handles the dialogue UI. Basically the main app window works well.
    ///   - onResult: Called on when a result is obtained. Passes if the age is eligible + verification result value.
    func triggerAgeVerificationIfNeeded(
        hostingWindow: UIWindow,
        onResult: @escaping (AppAccessDescision, AgeRangeVerificationResult) -> Void
    ) {
        guard featureFlagService.isFeatureFlagEnabled(.ageRangeRequirementsCompliance) else {
            onResult(.allow, .featureUnavailable)
            return
        }

        performAgeVerification(hostingWindow: hostingWindow, onResult: onResult)
    }
}

private extension AgeRangeVerificationCoordinator {
    func performAgeVerification(
        hostingWindow: UIWindow,
        onResult: @escaping (AppAccessDescision, AgeRangeVerificationResult) -> Void
    ) {
        guard let anchor = hostingWindow.topmostPresentedViewController else {
            DDLogWarn("Failed to obtain view controller to present `Declared Age Range` SDK dialogue.")
            // Allow flow to continue if we can't present the dialogue.
            onResult(.allow, .invalidUIState)
            return
        }

        ageRangeVerificationService.verifyAgeRange(
            in: anchor,
            minimumAge: Constants.minimumTOSRequiredAge
        ) { result in
            switch result {
            case let .eligible(significantAppChangeApprovalRequired, isMinor):
                DDLogInfo(
                    "Age is eligible. significantAppChangeApprovalRequired: \(significantAppChangeApprovalRequired), isMinor: \(isMinor)"
                )
                Task { @MainActor in
                    let ageRatingChange = await self.ageRatingChangeDetector.checkForChange()
                    let outcome = await self.significantChangeConsentCoordinator.checkConsentIfNeeded(
                        in: anchor,
                        isMinor: isMinor,
                        significantAppChangeApprovalRequired: significantAppChangeApprovalRequired,
                        ageRatingChange: ageRatingChange
                    )
                    switch outcome {
                    case .denied:
                        // TODO: decide on a dedicated result when consent is rejected.
                        onResult(.denyAndLogout, .ineligible)
                    case .granted, .notAvailable, .unknown:
                        onResult(.allow, result)
                    }
                }
            case .ineligible:
                onResult(.denyAndLogout, result)
            case .declinedSharing,
                 .featureUnavailable,
                 .ineligibleForAgeFeatures,
                 .invalidUIState,
                 .sdkError,
                 .unknown:
                // Non-deterministic/unavailable results are treated as allowed.
                onResult(.allow, result)
            }
        }
    }
}
