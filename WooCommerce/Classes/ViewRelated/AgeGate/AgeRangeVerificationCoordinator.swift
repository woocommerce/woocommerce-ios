import UIKit

protocol AgeRangeVerificationCoordinatorProtocol {
    func triggerAgeVerificationIfNeeded(
        hostingWindow: UIWindow,
        onResult: @escaping (Bool, AgeRangeVerificationResult) -> Void
    )
}

final class AgeRangeVerificationCoordinator: AgeRangeVerificationCoordinatorProtocol {
    /// Triggers the age range verification flow.
    /// Handles "blocking UI" presenting in case of ineligible age and performs a logout.
    /// - Parameters:
    ///   - hostingWindow: The window that handles the dialogue UI. Basically the main app window works well.
    ///   - onResult: Called on when a result is obtained. Passes if the age is eligible + verification result value.
    func triggerAgeVerificationIfNeeded(
        hostingWindow: UIWindow,
        onResult: @escaping (Bool, AgeRangeVerificationResult) -> Void
    ) {
        guard let anchor = hostingWindow.topmostPresentedViewController else {
            DDLogWarn("Failed to obtain view controller to present `Declared Age Range` SDK dialogue.")
            return
        }

        ServiceLocator.ageRangeVerificationService.verifyAgeRange(
            in: anchor,
            minimumAge: 18
        ) { result in
            let isEligible: Bool
            switch result {
            case .eligible:
                isEligible = true
            case .ineligible:
                isEligible = false
            case .declinedSharing,
                 .featureUnavailable,
                 .invalidUIState,
                 .sdkError,
                 .unknown:
                isEligible = true
            }

            onResult(isEligible, result)
        }
    }
}
