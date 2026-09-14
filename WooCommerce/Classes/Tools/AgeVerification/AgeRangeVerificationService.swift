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
            guard isVerificationInProgress == false else { return }
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
        do {
            let provider = provider
            requirements = try await Task.detached(priority: .userInitiated) {
                try await provider.retrieveAgeRangeRequirements()
            }.value
        } catch let providerError as AgeRangeProviderError where providerError.isPreflightUnavailable {
            // No preflight API on this OS (iOS 26.0–26.1): the age range request is the only signal.
            requirements = nil
        } catch {
            DDLogError("Age Range: Failed to fetch regulatory requirements; skipping the age range request. Error: \(error)")
            if let providerError = error as? AgeRangeProviderError,
               case let .other(underlyingError) = providerError {
                crashLogging.logError(
                    underlyingError,
                    userInfo: ["operation": "retrieve_age_range_requirements"],
                    level: .warning
                )
            }
            // Fail open, like every other provider error. Asking without a verdict would send
            // users outside any regulated regime into the system sheet; the next launch re-checks.
            return .sdkError(error)
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

        do {
            let snapshot = try await provider.requestAgeRange(
                minimumAge: minimumAge,
                in: anchor
            )
            let result = mapSnapshotToResult(
                snapshot,
                minimumAge: minimumAge,
                significantAppChangeApprovalRequired: requirements?.significantAppChangeApprovalRequired
            )
            DDLogInfo("Age Range: Response mapped to \(result)")
            return result
        } catch {
            if let providerError = error as? AgeRangeProviderError {
                switch providerError {
                case .declinedSharing:
                    return .declinedSharing
                case .notAvailable:
                    DDLogInfo("Age Range: Not available (simulator or account not eligible); skipping further prompts.")
                case .unknown:
                    return .unknown
                case .other(let underlying):
                    DDLogError("Age Range: Failed to retrieve age range. Error: \(underlying)")
                }
            } else {
                DDLogError("Age Range: Failed to retrieve age range. Error: \(error)")
            }
            return .sdkError(error)
        }
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
                isMinor: isMinor(lowerBound: lowerBound)
            )
        }
        return .ineligible
    }

    func isMinor(lowerBound: Int?) -> Bool {
        guard let lowerBound else { return false }
        return lowerBound < 18
    }
}

private extension AgeRangeProviderError {
    /// The preflight API itself is missing on this OS, as opposed to the system failing to answer.
    var isPreflightUnavailable: Bool {
        if case .notAvailable = self {
            return true
        }
        return false
    }
}
