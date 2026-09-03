import UIKit
import Experiments

enum AppAccessDecision: Equatable {
    case allow
    case denyAndLogout
    /// A significant-change consent is awaiting the parent/guardian answer.
    /// Recoverable: block the UI, keep the session, re-check on demand.
    case restrictPendingConsent
    /// The parent/guardian declined the significant-change consent.
    /// Recoverable: block the UI, keep the session, allow re-asking.
    case restrictDeniedConsent
}

protocol AgeRangeVerificationCoordinatorProtocol {
    func triggerAgeVerificationIfNeeded(
        hostingWindow: UIWindow,
        onResult: @escaping (AppAccessDecision, AgeRangeVerificationResult) -> Void
    )

    /// Starts listening for parent/guardian answers to significant-change consent questions.
    /// `onResolution` fires on the main actor whenever an outstanding question is answered.
    func startObservingConsentResponses(onResolution: @escaping @MainActor () -> Void)

    /// Clears a denied significant-change consent so the question can be sent again.
    func resetDeniedSignificantChangeConsent() async
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
        ageRatingChangeDetector: AgeRatingChangeDetecting = AgeRatingChangeDetector()
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
        onResult: @escaping (AppAccessDecision, AgeRangeVerificationResult) -> Void
    ) {
        guard featureFlagService.isFeatureFlagEnabled(.ageRangeRequirementsCompliance) else {
            onResult(.allow, .featureUnavailable)
            return
        }

        performAgeVerification(hostingWindow: hostingWindow, onResult: onResult)
    }

    func startObservingConsentResponses(onResolution: @escaping @MainActor () -> Void) {
        significantChangeConsentCoordinator.startObservingResponses { _ in
            onResolution()
        }
    }

    func resetDeniedSignificantChangeConsent() async {
        guard let change = await ageRatingChangeDetector.checkForChange(),
              case let .ageRatingChanged(_, current) = change else {
            return
        }
        significantChangeConsentCoordinator.resetDeniedConsent(for: .ageRatingChange(ratingCode: current))
    }
}

private extension AgeRangeVerificationCoordinator {
    func performAgeVerification(
        hostingWindow: UIWindow,
        onResult: @escaping (AppAccessDecision, AgeRangeVerificationResult) -> Void
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
                guard isMinor, significantAppChangeApprovalRequired else {
                    onResult(.allow, result)
                    return
                }

                Task { @MainActor in
                    let ageRatingChange = await self.ageRatingChangeDetector.checkForChange()
                    let state = await self.significantChangeConsentCoordinator.checkConsentIfNeeded(
                        in: anchor,
                        ageRatingChange: ageRatingChange
                    )
                    switch state {
                    case .notRequired, .notAvailable:
                        onResult(.allow, result)
                    case .granted:
                        // Acknowledge only once the change is approved, so an unresolved change
                        // keeps being re-evaluated on subsequent launches.
                        if case let .ageRatingChanged(_, current) = ageRatingChange {
                            self.ageRatingChangeDetector.acknowledge(ratingCode: current)
                        }
                        onResult(.allow, result)
                    case .pending:
                        onResult(.restrictPendingConsent, result)
                    case .denied:
                        onResult(.restrictDeniedConsent, result)
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
