import Foundation
import protocol WooFoundationCore.WooAnalyticsEventPropertyType

extension WooAnalyticsEvent {
    /// Age verification and parental consent events. Every property is categorical (Legal guidance):
    /// coarse age bands, SDK error domain + numeric code, no question ids or identifiers.
    enum AgeVerification {
        /// Coarse outcome of the Declared Age Range request. Bands match what Android reports.
        enum AgeRangeOutcome: String {
            /// 13+ and not a minor.
            case eligible
            /// Eligible minor. iOS requests gates 13 and 18 only, so Android's 13–15 / 16–17 split isn't available.
            case age13To17 = "age_13_17"
            case below13 = "below_13"
            case declinedSharing = "declined_sharing"
            /// Feature flag off, or the age range API isn't available on this OS/account.
            case unavailable
            /// The account isn't under a covered regime.
            case notApplicable = "not_applicable"
            case invalidUIState = "invalid_ui_state"
            case sdkError = "sdk_error"
            case unknown
        }

        enum FinalDecision: String {
            case allowed
            /// Logged out: the declared age is below the minimum.
            case restricted
            case wallConsentRequired = "wall_consent_required"
            case wallConsentPending = "wall_consent_pending"
            case wallConsentDenied = "wall_consent_denied"
        }

        enum RestrictionReason: String {
            case belowMinimumAge = "below_minimum_age"
            case consentRequired = "consent_required"
            case consentPending = "consent_pending"
            case consentDenied = "consent_denied"
        }

        enum SignificantChangeStatus: String {
            case notApplicable = "not_applicable"
            /// A change is outstanding and the question hasn't been sent yet (iOS-only: the app sends it).
            case required
            case approved
            case pending
            case declined
            case unavailable
        }

        enum Screen: String {
            case consentNeeded = "consent_needed"
            case consentPending = "consent_pending"
            case consentDenied = "consent_denied"
            case consentGranted = "consent_granted"
            case underageAlert = "underage_alert"
        }

        enum Action: String {
            case requestApproval = "request_approval"
            case checkAgain = "check_again"
            case askAgain = "ask_again"
            case `continue`
        }

        enum ChangeType: String {
            case ageRating = "age_rating"
            case manual
        }

        enum ConsentRequestResult: String {
            case sent
            case notAvailable = "not_available"
            case failed
        }

        enum ConsentResolution: String {
            case granted
            case denied
        }

        enum ResolutionPath: String {
            /// Answered within the short window right after the question was sent.
            case graceWindow = "grace_window"
            /// Answered later, through the long-lived response listener.
            case listener
        }

        private enum Keys {
            static let trigger = "trigger"
            static let ageRangeOutcome = "age_range_outcome"
            static let finalDecision = "final_decision"
            static let restrictionReason = "restriction_reason"
            static let significantChangeStatus = "significant_change_status"
            static let sdkErrorDomain = "sdk_error_domain"
            static let sdkErrorCode = "sdk_error_code"
            static let screen = "screen"
            static let action = "action"
            static let changeType = "change_type"
            static let result = "result"
            static let isReask = "is_reask"
            static let resolution = "resolution"
            static let via = "via"
        }

        /// One completed verification flow.
        /// - Parameter consentState: the consent state when the significant-change branch ran; `nil` otherwise.
        static func restrictionChecked(
            trigger: AgeVerificationTrigger,
            decision: AppAccessDecision,
            result: AgeRangeVerificationResult,
            consentState: SignificantChangeConsentState?
        ) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Keys.trigger: trigger.rawValue,
                Keys.ageRangeOutcome: ageRangeOutcome(for: result).rawValue,
                Keys.finalDecision: finalDecision(for: decision).rawValue
            ]
            if let reason = restrictionReason(for: decision) {
                properties[Keys.restrictionReason] = reason.rawValue
            }
            if let consentState {
                properties[Keys.significantChangeStatus] = significantChangeStatus(for: consentState).rawValue
            }
            if case let .sdkError(error) = result, let error = reportableError(error) {
                properties[Keys.sdkErrorDomain] = error.domain
                properties[Keys.sdkErrorCode] = Int64(error.code)
            }
            return WooAnalyticsEvent(statName: .accountAgeRestrictionChecked, properties: properties)
        }

        /// A blocking wall or the underage alert became visible.
        static func dialogShown(screen: Screen) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .accountAgeRestrictionDialogShown, properties: [Keys.screen: screen.rawValue])
        }

        /// The blocking wall became visible in the given context.
        static func dialogShown(for context: SignificantChangeBlockingContext) -> WooAnalyticsEvent {
            dialogShown(screen: screenValue(for: context))
        }

        /// A tap on the blocking wall's button in the given context.
        static func action(for context: SignificantChangeBlockingContext) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .accountAgeVerificationAction, properties: [Keys.action: actionValue(for: context).rawValue])
        }

        /// The app handed a consent question to the system (iOS-only; on Android, Play manages the ask).
        static func consentRequested(
            changeType: ChangeType,
            result: ConsentRequestResult,
            isReask: Bool
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .accountAgeConsentRequested, properties: [
                Keys.changeType: changeType.rawValue,
                Keys.result: result.rawValue,
                Keys.isReask: isReask
            ])
        }

        /// A parent/guardian answer was processed (iOS-only).
        static func consentResolved(resolution: ConsentResolution, via: ResolutionPath) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .accountAgeConsentResolved, properties: [
                Keys.resolution: resolution.rawValue,
                Keys.via: via.rawValue
            ])
        }
    }
}

// MARK: - Mappings

extension WooAnalyticsEvent.AgeVerification {
    static func ageRangeOutcome(for result: AgeRangeVerificationResult) -> AgeRangeOutcome {
        switch result {
        case let .eligible(_, isMinor): return isMinor ? .age13To17 : .eligible
        case .ineligible: return .below13
        case .declinedSharing: return .declinedSharing
        case .ineligibleForAgeFeatures: return .notApplicable
        case .featureUnavailable: return .unavailable
        case .invalidUIState: return .invalidUIState
        case let .sdkError(error): return reportableError(error) == nil ? .unavailable : .sdkError
        case .unknown: return .unknown
        }
    }

    static func finalDecision(for decision: AppAccessDecision) -> FinalDecision {
        switch decision {
        case .allow, .allowConsentGranted: return .allowed
        case .denyAndLogout: return .restricted
        case .restrictConsentRequired: return .wallConsentRequired
        case .restrictPendingConsent: return .wallConsentPending
        case .restrictDeniedConsent: return .wallConsentDenied
        }
    }

    static func restrictionReason(for decision: AppAccessDecision) -> RestrictionReason? {
        switch decision {
        case .allow, .allowConsentGranted: return nil
        case .denyAndLogout: return .belowMinimumAge
        case .restrictConsentRequired: return .consentRequired
        case .restrictPendingConsent: return .consentPending
        case .restrictDeniedConsent: return .consentDenied
        }
    }

    static func significantChangeStatus(for state: SignificantChangeConsentState) -> SignificantChangeStatus {
        switch state {
        case .notRequired: return .notApplicable
        case .required: return .required
        case .granted: return .approved
        case .pending: return .pending
        case .denied: return .declined
        case .notAvailable: return .unavailable
        }
    }

    private static func screenValue(for context: SignificantChangeBlockingContext) -> Screen {
        switch context {
        case .approvalNeeded: return .consentNeeded
        case .pendingApproval: return .consentPending
        case .approvalDenied: return .consentDenied
        case .approvalGranted: return .consentGranted
        }
    }

    private static func actionValue(for context: SignificantChangeBlockingContext) -> Action {
        switch context {
        case .approvalNeeded: return .requestApproval
        case .pendingApproval: return .checkAgain
        case .approvalDenied: return .askAgain
        case .approvalGranted: return .continue
        }
    }

    static func changeType(for identifier: SignificantChangeIdentifier) -> ChangeType {
        switch identifier {
        case .ageRatingChange: return .ageRating
        case .manual: return .manual
        }
    }

    /// Domain and code of a genuine SDK failure. `notAvailable` is an unsupported OS/account, not an error.
    private static func reportableError(_ error: Error) -> NSError? {
        guard let providerError = error as? AgeRangeProviderError else {
            return error as NSError
        }
        switch providerError {
        case let .other(underlying): return underlying as NSError
        case .notAvailable, .declinedSharing, .unknown: return nil
        }
    }
}
