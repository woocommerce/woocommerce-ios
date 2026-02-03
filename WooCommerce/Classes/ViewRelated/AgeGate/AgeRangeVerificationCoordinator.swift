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
            let decision: AppAccessDescision
            switch result {
            case let .eligible(significantAppChangeApprovalRequired, isMinor):
                // TODO: if isMinor && significantAppChangeApprovalRequired, trigger app age rating change check
                // and parental consent flow (separate coordinator) before allowing access.
                DDLogInfo(
                    "Age is eligible. significantAppChangeApprovalRequired: \(significantAppChangeApprovalRequired), isMinor: \(isMinor)"
                )
                decision = .allow
            case .ineligible:
                decision = .denyAndLogout
            case .declinedSharing,
                 .featureUnavailable,
                 .ineligibleForAgeFeatures,
                 .invalidUIState,
                 .sdkError,
                 .unknown:
                // Non-deterministic/unavailable results are treated as allowed.
                decision = .allow
            }

            onResult(decision, result)
        }
    }
}
