import UIKit
import Experiments

protocol AgeRangeVerificationCoordinatorProtocol {
    func triggerAgeVerificationIfNeeded(
        hostingWindow: UIWindow,
        onResult: @escaping (Bool, AgeRangeVerificationResult) -> Void
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

    init(
        featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
        ageRangeVerificationService: AgeRangeVerificationServiceProtocol = ServiceLocator.ageRangeVerificationService
    ) {
        self.featureFlagService = featureFlagService
        self.ageRangeVerificationService = ageRangeVerificationService
    }

    /// Triggers the age range verification flow.
    /// Handles "blocking UI" presenting in case of ineligible age and performs a logout.
    /// - Parameters:
    ///   - hostingWindow: The window that handles the dialogue UI. Basically the main app window works well.
    ///   - onResult: Called on when a result is obtained. Passes if the age is eligible + verification result value.
    func triggerAgeVerificationIfNeeded(
        hostingWindow: UIWindow,
        onResult: @escaping (Bool, AgeRangeVerificationResult) -> Void
    ) {
        guard featureFlagService.isFeatureFlagEnabled(.ageRangeRequirementsCompliance) else {
            onResult(true, .featureUnavailable)
            return
        }

        ageRangeVerificationService.fetchIsEligibleForAgeFeatures { [weak self] eligibility in
            guard let self else {
                onResult(true, .unknown)
                return
            }

            // Fail open: if not eligible or unavailable, allow without prompting.
            if eligibility == false {
                onResult(true, .ineligibleForAgeFeatures)
                return
            }

            self.performAgeVerification(hostingWindow: hostingWindow, onResult: onResult)
        }
    }
}

private extension AgeRangeVerificationCoordinator {
    func performAgeVerification(
        hostingWindow: UIWindow,
        onResult: @escaping (Bool, AgeRangeVerificationResult) -> Void
    ) {
        guard let anchor = hostingWindow.topmostPresentedViewController else {
            DDLogWarn("Failed to obtain view controller to present `Declared Age Range` SDK dialogue.")
            // Allow flow to continue if we can't present the dialogue.
            onResult(true, .invalidUIState)
            return
        }

        ageRangeVerificationService.verifyAgeRange(
            in: anchor,
            minimumAge: Constants.minimumTOSRequiredAge
        ) { result in
            let isEligible: Bool
            switch result {
            case let .eligible(significantAppChangeApprovalRequired, isMinor):
                // TODO: if isMinor && significantAppChangeApprovalRequired, trigger app age rating change check
                // and parental consent flow (separate coordinator) before allowing access.
                isEligible = true
            case .ineligible:
                isEligible = false
            case .declinedSharing,
                 .featureUnavailable,
                 .ineligibleForAgeFeatures,
                 .invalidUIState,
                 .sdkError,
                 .unknown:
                // Non-deterministic/unavailable results are treated as allowed.
                isEligible = true
            }

            onResult(isEligible, result)
        }
    }
}
