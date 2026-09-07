import UIKit
import Experiments
import protocol WooFoundation.Analytics

enum AppAccessDecision: Equatable {
    case allow
    /// Access is allowed because the parent/guardian approved the outstanding significant change.
    /// Distinct from `allow` so a blocking screen that is up can confirm what happened
    /// instead of silently disappearing.
    case allowConsentGranted
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
    private let analytics: Analytics
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
            CurrentSignificantChange.activeManualChangeIdentifier()
        },
        analytics: Analytics = ServiceLocator.analytics
    ) {
        self.featureFlagService = featureFlagService
        self.ageRangeVerificationService = ageRangeVerificationService
        self.significantChangeConsentCoordinator = significantChangeConsentCoordinator
        self.ageRatingChangeDetector = ageRatingChangeDetector
        self.manualChangeIdentifierProvider = manualChangeIdentifierProvider
        self.analytics = analytics
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
        let finish = { [weak self] (decision: AppAccessDecision, result: AgeRangeVerificationResult, consentState: SignificantChangeConsentState?) in
            self?.trackVerificationIfNeeded(decision: decision, result: result, consentState: consentState)
            onResult(decision, result)
        }

        guard let anchor = hostingWindow.topmostPresentedViewController else {
            DDLogWarn("Failed to obtain view controller to present `Declared Age Range` SDK dialogue.")
            // Allow flow to continue if we can't present the dialogue.
            finish(.allow, .invalidUIState, nil)
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
                    finish(.allow, result, nil)
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
                        finish(.allow, result, state)
                    case .granted:
                        // Acknowledge only once the change is approved, so an unresolved change
                        // keeps being re-evaluated on subsequent launches. A manual change takes
                        // precedence in the check, so its approval says nothing about a concurrent
                        // rating change — that one stays outstanding.
                        if manualChangeIdentifier == nil, case let .ageRatingChanged(_, current) = ageRatingChange {
                            self.ageRatingChangeDetector.acknowledge(ratingCode: current)
                        }
                        finish(.allowConsentGranted, result, state)
                    case .required:
                        finish(.restrictConsentRequired, result, state)
                    case .pending:
                        finish(.restrictPendingConsent, result, state)
                    case .denied:
                        finish(.restrictDeniedConsent, result, state)
                    }
                }
            case .ineligible:
                finish(.denyAndLogout, result, nil)
            case .declinedSharing,
                 .featureUnavailable,
                 .ineligibleForAgeFeatures,
                 .invalidUIState,
                 .sdkError,
                 .unknown:
                // Non-deterministic/unavailable results are treated as allowed.
                finish(.allow, result, nil)
            }
        }
    }

    /// Volume guardrail: the gate runs on every logged-in transition for every user, and nearly all
    /// of them are uninteresting allows (account not under a covered regime, API unavailable on
    /// older iOS). Only a flow that got past the compliance-required check, or any decision other
    /// than `allow`, is worth an event. The covered population is tiny, so these events are rare
    /// by nature.
    func trackVerificationIfNeeded(
        decision: AppAccessDecision,
        result: AgeRangeVerificationResult,
        consentState: SignificantChangeConsentState?
    ) {
        guard decision != .allow || result.isUnderCoveredRegime else { return }
        analytics.track(event: .AgeVerification.restrictionChecked(decision: decision, result: result, consentState: consentState))
    }
}

private extension AgeRangeVerificationResult {
    /// Whether the flow got past the compliance-required check, i.e. the account is under a covered regime.
    var isUnderCoveredRegime: Bool {
        switch self {
        case .eligible, .ineligible, .declinedSharing, .unknown:
            return true
        case let .sdkError(error):
            // `notAvailable` is the unsupported OS/account case, reached before any regime check.
            if let providerError = error as? AgeRangeProviderError, case .notAvailable = providerError {
                return false
            }
            return true
        case .featureUnavailable, .ineligibleForAgeFeatures, .invalidUIState:
            return false
        }
    }
}
