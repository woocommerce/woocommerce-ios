import Foundation
import CocoaLumberjack
import UIKit
import protocol WooFoundationCore.CrashLogger

enum AgeRangeVerificationResult {
    /// The feature is supported and declared user age is within the required range.
    /// Carries the `significantAppChangeApprovalRequired` flag when available.
    case eligible(significantAppChangeApprovalRequired: Bool, isMinor: Bool)

    /// The feature is supported but declared user age is outside of the required range
    case ineligible

    /// User or parent refused from age sharing
    case declinedSharing

    /// The provider reports the app/account as ineligible for age-based features.
    case ineligibleForAgeFeatures

    /// The provider indicates the age feature is unavailable in the current environment.
    case featureUnavailable

    /// Failed to obtain a view controller suitable for system Age Range dialogue. I.e. the provided view controller is outside of UI stack or not presented.
    case invalidUIState

    /// The age range provider produced an error.
    case sdkError(Error)

    case unknown
}

protocol AgeRangeVerificationServiceProtocol {
    /// Triggers the age range verification flow.
    /// - Parameters:
    ///   - viewController: Anchor for the system sheet/prompt.
    ///   - minimumAge: Primary age gate (required).
    ///   - completion: Called with the interpreted outcome.
    func verifyAgeRange(
        in viewController: UIViewController,
        minimumAge: Int,
        completion: @escaping (AgeRangeVerificationResult) -> Void
    )
}

final class AgeRangeVerificationService: AgeRangeVerificationServiceProtocol {
    private let provider: AgeRangeProviding
    private let crashLogging: CrashLogger
    @MainActor private var isVerificationInProgress = false
    @MainActor private var pendingCompletions: [(AgeRangeVerificationResult) -> Void] = []

    init(
        provider: AgeRangeProviding = DeclaredAgeRangeProvider(),
        crashLogging: CrashLogger = ServiceLocator.crashLogging
    ) {
        self.provider = provider
        self.crashLogging = crashLogging
    }

    /// Requests the user's declared age range via the provider.
    func verifyAgeRange(
        in viewController: UIViewController,
        minimumAge: Int,
        completion: @escaping (AgeRangeVerificationResult) -> Void
    ) {
        Task { @MainActor in
            pendingCompletions.append(completion)
            guard isVerificationInProgress == false else {
                logBreadcrumb("Verification joined the in-flight request")
                return
            }
            isVerificationInProgress = true

            let result = await performVerification(in: viewController, minimumAge: minimumAge)
            finishVerification(with: result)
        }
    }

    // Eligibility checks are handled internally as part of verifyAgeRange.
}

private extension AgeRangeVerificationService {
    @MainActor
    func performVerification(
        in viewController: UIViewController,
        minimumAge: Int
    ) async -> AgeRangeVerificationResult {
        let requirements: AgeRangeRequirements?
        let requirementsStart = Date()
        logBreadcrumb("Requirements fetch started")
        do {
            let provider = provider
            let fetched = try await Task.detached(priority: .userInitiated) {
                try await provider.retrieveAgeRangeRequirements()
            }.value
            requirements = fetched
            logBreadcrumb("Requirements fetch finished", [
                "compliance_required": fetched.isComplianceRequired,
                "duration_ms": elapsedMilliseconds(since: requirementsStart)
            ])
        } catch {
            logBreadcrumb("Requirements fetch failed", [
                "error": errorLabel(error),
                "duration_ms": elapsedMilliseconds(since: requirementsStart)
            ])
            DDLogError("Age Range: Failed to fetch regulatory requirements. Error: \(error)")
            if let providerError = error as? AgeRangeProviderError,
               case let .other(underlyingError) = providerError {
                crashLogging.logError(
                    underlyingError,
                    userInfo: ["operation": "retrieve_age_range_requirements"],
                    level: .warning
                )
            }
            requirements = nil
        }

        if requirements?.isComplianceRequired == false {
            return .ineligibleForAgeFeatures
        }

        // Use the topmost visible controller as the anchor to ensure UI can be presented.
        let anchor = viewController.topmostPresentedViewController
        guard anchor.view.window != nil else {
            DDLogWarn("Age Range: Anchor viewController is not in window; skipping request.")
            return .invalidUIState
        }

        let requestStart = Date()
        logBreadcrumb("Age range request started")
        do {
            let snapshot = try await provider.requestAgeRange(
                minimumAge: minimumAge,
                adultAge: Constants.adultAgeThreshold,
                in: anchor
            )
            let result = mapSnapshotToResult(
                snapshot,
                minimumAge: minimumAge,
                significantAppChangeApprovalRequired: requirements?.significantAppChangeApprovalRequired
            )
            logBreadcrumb("Age range request finished", [
                "outcome": WooAnalyticsEvent.AgeVerification.ageRangeOutcome(for: result).rawValue,
                "duration_ms": elapsedMilliseconds(since: requestStart)
            ])
            DDLogInfo("Age Range: Response mapped to \(result)")
            return result
        } catch {
            let result = mapErrorToResult(error)
            logBreadcrumb("Age range request failed", [
                "outcome": WooAnalyticsEvent.AgeVerification.ageRangeOutcome(for: result).rawValue,
                "error": errorLabel(error),
                "duration_ms": elapsedMilliseconds(since: requestStart)
            ])
            return result
        }
    }

    func mapErrorToResult(_ error: Error) -> AgeRangeVerificationResult {
        guard let providerError = error as? AgeRangeProviderError else {
            DDLogError("Age Range: Failed to retrieve age range. Error: \(error)")
            return .sdkError(error)
        }
        switch providerError {
        case .declinedSharing:
            return .declinedSharing
        case .notAvailable:
            DDLogInfo("Age Range: Not available (simulator or account not eligible); skipping further prompts.")
            return .sdkError(error)
        case .unknown:
            return .unknown
        case .other(let underlying):
            DDLogError("Age Range: Failed to retrieve age range. Error: \(underlying)")
            return .sdkError(error)
        }
    }

    /// Marks a step of the flow in the crash report trail, so a crash inside the system
    /// frameworks shows which call was in flight and for how long.
    func logBreadcrumb(_ message: String, _ properties: [String: Any] = [:]) {
        crashLogging.logBreadcrumb(message, category: Constants.breadcrumbCategory, properties: properties)
    }

    func errorLabel(_ error: Error) -> String {
        guard let providerError = error as? AgeRangeProviderError else {
            return String(describing: error)
        }
        switch providerError {
        case .declinedSharing:
            return "declined_sharing"
        case .notAvailable:
            return "not_available"
        case .unknown:
            return "unknown"
        case .other(let underlying):
            return String(describing: underlying)
        }
    }

    func elapsedMilliseconds(since start: Date) -> Int {
        Int(Date().timeIntervalSince(start) * 1000)
    }

    @MainActor
    func finishVerification(with result: AgeRangeVerificationResult) {
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        isVerificationInProgress = false
        completions.forEach { $0(result) }
    }

    func mapSnapshotToResult(
        _ snapshot: AgeRangeSnapshot,
        minimumAge: Int,
        significantAppChangeApprovalRequired: Bool?
    ) -> AgeRangeVerificationResult {
        if let lowerBound = snapshot.lowerBound, lowerBound >= minimumAge {
            return .eligible(
                // On iOS 26.4+, use the regulatory requirements value whenever it was retrieved,
                // including `false`; otherwise fall back to the legacy snapshot.
                significantAppChangeApprovalRequired: significantAppChangeApprovalRequired ?? snapshot.significantAppChangeApprovalRequired,
                isMinor: isMinor(upperBound: snapshot.upperBound)
            )
        }
        return .ineligible
    }

    /// A user counts as a minor only on affirmative evidence: a declared upper bound below the
    /// adult threshold. Responses are quantized to the requested age gates, so the adult band
    /// carries a nil upper bound — and a degenerate response without bounds must not gate anyone.
    func isMinor(upperBound: Int?) -> Bool {
        guard let upperBound else { return false }
        return upperBound < Constants.adultAgeThreshold
    }
}

private extension AgeRangeVerificationService {
    enum Constants {
        /// Second age gate: separates minors (13–17) from adults. Without it, responses can't
        /// distinguish a 16-year-old from an adult — both would report only "13 or older".
        static let adultAgeThreshold = 18
        static let breadcrumbCategory = "age_verification"
    }
}
