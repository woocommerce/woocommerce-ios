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
    /// Returns the resulting consent state — `.notAvailable` when the system can't take the question.
    func requestSignificantChangeConsent(hostingWindow: UIWindow) async -> SignificantChangeConsentState
}

extension AgeRangeVerificationCoordinator {
    enum Constants {
        static let minimumTOSRequiredAge = 13
    }
}

final class AgeRangeVerificationCoordinator: AgeRangeVerificationCoordinatorProtocol {
    typealias VerificationTrigger = (hostingWindow: UIWindow, onResult: (AppAccessDecision, AgeRangeVerificationResult) -> Void)

    private let featureFlagService: FeatureFlagService
    private let ageRangeVerificationService: AgeRangeVerificationServiceProtocol
    private let significantChangeConsentCoordinator: SignificantChangeConsentCoordinator
    private let ageRatingChangeDetector: AgeRatingChangeDetecting
    private let manualChangeIdentifierProvider: () -> SignificantChangeIdentifier?
    /// Guards against concurrent decision flows. All trigger sources (launch, consent
    /// resolution, foreground re-check, blocker buttons) run on the main thread.
    private var isVerificationFlowInProgress = false
    /// The latest trigger that arrived while a flow was in progress; replayed once it finishes.
    private var queuedTrigger: VerificationTrigger?

    init(
        featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
        ageRangeVerificationService: AgeRangeVerificationServiceProtocol = ServiceLocator.ageRangeVerificationService,
        significantChangeConsentCoordinator: SignificantChangeConsentCoordinator = SignificantChangeConsentCoordinator(),
        ageRatingChangeDetector: AgeRatingChangeDetecting = AgeRatingChangeDetector(),
        manualChangeIdentifierProvider: @escaping () -> SignificantChangeIdentifier? = {
            DebugAgeVerificationOverrides.manualSignificantChangeIdentifier
        }
    ) {
        self.featureFlagService = featureFlagService
        self.ageRangeVerificationService = ageRangeVerificationService
        self.significantChangeConsentCoordinator = significantChangeConsentCoordinator
        self.ageRatingChangeDetector = ageRatingChangeDetector
        self.manualChangeIdentifierProvider = manualChangeIdentifierProvider
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
        // questions and fight over the blocker presentation. A trigger that lands mid-flow is
        // not dropped, though — it may carry news the running flow read too early (e.g. a
        // consent answer arriving during a foreground re-check). It's replayed once the current
        // flow finishes; only the latest one is kept since a single follow-up pass covers them all.
        guard isVerificationFlowInProgress == false else {
            DDLogInfo("Age verification flow already in progress; queueing a follow-up check.")
            queuedTrigger = (hostingWindow, onResult)
            return
        }
        isVerificationFlowInProgress = true

        performAgeVerification(hostingWindow: hostingWindow) { [weak self] decision, result in
            self?.isVerificationFlowInProgress = false
            onResult(decision, result)
            self?.replayQueuedTriggerIfNeeded()
        }
    }

    func startObservingConsentResponses(onResolution: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            self.significantChangeConsentCoordinator.startObservingResponses { _ in
                onResolution()
            }
        }
    }

    func requestSignificantChangeConsent(hostingWindow: UIWindow) async -> SignificantChangeConsentState {
        guard let anchor = hostingWindow.topmostPresentedViewController else {
            DDLogWarn("Failed to obtain view controller to anchor the consent request.")
            return .notAvailable
        }
        let ageRatingChange = await ageRatingChangeDetector.checkForChange()
        return await significantChangeConsentCoordinator.requestConsent(
            in: anchor,
            ageRatingChange: ageRatingChange,
            manualChangeIdentifier: manualChangeIdentifierProvider()
        )
    }
}

private extension AgeRangeVerificationCoordinator {
    func replayQueuedTriggerIfNeeded() {
        guard let trigger = queuedTrigger else { return }
        queuedTrigger = nil
        triggerAgeVerificationIfNeeded(hostingWindow: trigger.hostingWindow, onResult: trigger.onResult)
    }

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
                    let manualChangeIdentifier = self.manualChangeIdentifierProvider()
                    let state = self.significantChangeConsentCoordinator.checkConsentIfNeeded(
                        ageRatingChange: ageRatingChange,
                        manualChangeIdentifier: manualChangeIdentifier
                    )
                    switch state {
                    case .notRequired, .notAvailable:
                        onResult(.allow, result)
                    case .granted:
                        // Acknowledge only once the change is approved, so an unresolved change
                        // keeps being re-evaluated on subsequent launches. A manual change takes
                        // precedence in the check, so its approval says nothing about a concurrent
                        // rating change — that one stays outstanding.
                        if manualChangeIdentifier == nil, case let .ageRatingChanged(_, current) = ageRatingChange {
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
