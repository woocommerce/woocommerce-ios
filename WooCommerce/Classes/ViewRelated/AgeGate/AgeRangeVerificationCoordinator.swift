import UIKit
import Experiments

enum AppAccessDecision: Equatable {
    case allow
    case denyAndLogout
    /// A significant change requires parental consent that hasn't been requested yet.
    /// Recoverable: block the UI, keep the session, let the user send the request.
    case restrictConsentRequired
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

    /// Sends the significant-change consent request for the currently outstanding change.
    /// Call only from an explicit user action; also re-sends after a previous denial.
    func requestSignificantChangeConsent(hostingWindow: UIWindow) async
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
    /// Guards against concurrent decision flows. All trigger sources (launch, consent
    /// resolution, foreground re-check, blocker buttons) run on the main thread.
    private var isVerificationFlowInProgress = false

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

        // Never run two decision flows concurrently: racing flows can send duplicate consent
        // questions and fight over the blocker presentation. Duplicate triggers are dropped;
        // every trigger source is a fire-and-forget re-check, so nothing waits on the result.
        guard isVerificationFlowInProgress == false else {
            DDLogInfo("Age verification flow already in progress; ignoring duplicate trigger.")
            return
        }
        isVerificationFlowInProgress = true

        performAgeVerification(hostingWindow: hostingWindow) { [weak self] decision, result in
            self?.isVerificationFlowInProgress = false
            onResult(decision, result)
        }
    }

    func startObservingConsentResponses(onResolution: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            self.significantChangeConsentCoordinator.startObservingResponses { _ in
                onResolution()
            }
        }
    }

    func requestSignificantChangeConsent(hostingWindow: UIWindow) async {
        guard let anchor = hostingWindow.topmostPresentedViewController else {
            DDLogWarn("Failed to obtain view controller to anchor the consent request.")
            return
        }
        let ageRatingChange = await ageRatingChangeDetector.checkForChange()
        _ = await significantChangeConsentCoordinator.requestConsent(
            in: anchor,
            ageRatingChange: ageRatingChange,
            manualChangeIdentifier: DebugAgeVerificationOverrides.manualSignificantChangeIdentifier
        )
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
                    let state = self.significantChangeConsentCoordinator.checkConsentIfNeeded(
                        ageRatingChange: ageRatingChange,
                        manualChangeIdentifier: DebugAgeVerificationOverrides.manualSignificantChangeIdentifier
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
                    case .required:
                        onResult(.restrictConsentRequired, result)
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
