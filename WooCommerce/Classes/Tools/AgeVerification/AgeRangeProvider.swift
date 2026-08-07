import Foundation
import UIKit
#if canImport(DeclaredAgeRange)
import DeclaredAgeRange
#endif

/// Snapshot of age range data used by our app logic (SDK-agnostic).
struct AgeRangeSnapshot: Sendable {
    /// Lower bound of the declared age range, if available.
    let lowerBound: Int?
    /// Whether parental approval is required for significant app changes.
    let significantAppChangeApprovalRequired: Bool
}

/// Regulatory requirements that determine whether the app needs to request the user's age range.
struct AgeRangeRequirements: Sendable {
    /// Whether any age-related compliance flow is required for the current user.
    let isComplianceRequired: Bool
    /// Whether a parent or guardian must approve significant app changes.
    /// A nil value means the legacy age range response should be used instead.
    let significantAppChangeApprovalRequired: Bool?
}

/// Abstraction over DeclaredAgeRange APIs for testability.
protocol AgeRangeProviding: Sendable {
    @MainActor
    func requestAgeRange(
        minimumAge: Int,
        in viewController: UIViewController
    ) async throws -> AgeRangeSnapshot

    func retrieveAgeRangeRequirements() async throws -> AgeRangeRequirements
}

enum AgeRangeProviderError: Error {
    case declinedSharing
    case notAvailable
    case unknown
    case other(Error)
}

#if canImport(DeclaredAgeRange)
/// Real adapter for DeclaredAgeRange (iOS 26+).
struct DeclaredAgeRangeProvider: AgeRangeProviding {
    @MainActor
    func requestAgeRange(
        minimumAge: Int,
        in viewController: UIViewController
    ) async throws -> AgeRangeSnapshot {
        guard #available(iOS 26.0, *) else {
            throw AgeRangeProviderError.notAvailable
        }
        do {
            let response = try await AgeRangeService.shared.requestAgeRange(
                ageGates: minimumAge,
                in: viewController
            )
            switch response {
            case let .sharing(range):
                let approvalRequired: Bool = {
                    // On iOS 26.4+ requiredRegulatoryFeatures is the primary source for this value,
                    // but keep reading activeParentalControls as a fallback for when that fetch fails.
                    if #available(iOS 26.2, *) {
                        return range.activeParentalControls.contains(.significantAppChangeApprovalRequired)
                    }
                    return false
                }()
                return AgeRangeSnapshot(
                    lowerBound: range.lowerBound,
                    significantAppChangeApprovalRequired: approvalRequired
                )
            case .declinedSharing:
                throw AgeRangeProviderError.declinedSharing
            @unknown default:
                throw AgeRangeProviderError.unknown
            }
        } catch {
            throw AgeRangeProviderError.other(error)
        }
    }

    func retrieveAgeRangeRequirements() async throws -> AgeRangeRequirements {
        guard #available(iOS 26.2, *) else {
            throw AgeRangeProviderError.notAvailable
        }
        do {
            if #available(iOS 26.4, *) {
                let features = try await AgeRangeService.shared.requiredRegulatoryFeatures
                return AgeRangeRequirements(
                    isComplianceRequired: !features.isEmpty,
                    significantAppChangeApprovalRequired: features.contains(.significantAppChangeRequiresParentalConsent)
                )
            }

            return AgeRangeRequirements(
                isComplianceRequired: try await AgeRangeService.shared.isEligibleForAgeFeatures,
                significantAppChangeApprovalRequired: nil
            )
        } catch {
            throw AgeRangeProviderError.other(error)
        }
    }
}
#else
/// Fallback adapter when DeclaredAgeRange is unavailable.
struct DeclaredAgeRangeProvider: AgeRangeProviding {
    @MainActor
    func requestAgeRange(
        minimumAge: Int,
        in viewController: UIViewController
    ) async throws -> AgeRangeSnapshot {
        throw AgeRangeProviderError.notAvailable
    }

    func retrieveAgeRangeRequirements() async throws -> AgeRangeRequirements {
        throw AgeRangeProviderError.notAvailable
    }
}
#endif
