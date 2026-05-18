import Foundation
import CocoaLumberjack
import UIKit

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

    init(provider: AgeRangeProviding = DeclaredAgeRangeProvider()) {
        self.provider = provider
    }

    /// Requests the user's declared age range via the provider.
    func verifyAgeRange(
        in viewController: UIViewController,
        minimumAge: Int,
        completion: @escaping (AgeRangeVerificationResult) -> Void
    ) {
        Task { @MainActor in
            let eligibility: Bool?
            do {
                eligibility = try await provider.isEligibleForAgeFeatures()
            } catch {
                DDLogError("Age Range: Failed to fetch eligibility signals. Error: \(error)")
                eligibility = nil
            }

            if eligibility == false {
                completion(.ineligibleForAgeFeatures)
                return
            }

            // Use the topmost visible controller as the anchor to ensure UI can be presented.
            let anchor = viewController.topmostPresentedViewController
            guard anchor.view.window != nil else {
                DDLogWarn("Age Range: Anchor viewController is not in window; skipping request.")
                completion(.invalidUIState)
                return
            }

            do {
                let snapshot = try await provider.requestAgeRange(
                    minimumAge: minimumAge,
                    in: anchor
                )
                let result = mapSnapshotToResult(
                    snapshot,
                    minimumAge: minimumAge
                )
                DDLogInfo("Age Range: Response mapped to \(result)")
                completion(result)
            } catch {
                if let providerError = error as? AgeRangeProviderError {
                    switch providerError {
                    case .declinedSharing:
                        completion(.declinedSharing)
                        return
                    case .notAvailable:
                        DDLogInfo("Age Range: Not available (simulator or account not eligible); skipping further prompts.")
                    case .unknown:
                        completion(.unknown)
                        return
                    case .other(let underlying):
                        DDLogError("Age Range: Failed to retrieve age range. Error: \(underlying)")
                    }
                } else {
                    DDLogError("Age Range: Failed to retrieve age range. Error: \(error)")
                }
                completion(.sdkError(error))
            }
        }
    }

    // Eligibility checks are handled internally as part of verifyAgeRange.
}

private extension AgeRangeVerificationService {
    func mapSnapshotToResult(
        _ snapshot: AgeRangeSnapshot,
        minimumAge: Int
    ) -> AgeRangeVerificationResult {
        if let lowerBound = snapshot.lowerBound, lowerBound >= minimumAge {
            return .eligible(
                significantAppChangeApprovalRequired: snapshot.significantAppChangeApprovalRequired,
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
