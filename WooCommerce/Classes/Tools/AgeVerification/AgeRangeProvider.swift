import Foundation
import UIKit
#if canImport(DeclaredAgeRange)
import DeclaredAgeRange
#endif

/// Snapshot of age range data used by our app logic (SDK-agnostic).
struct AgeRangeSnapshot {
    /// Lower bound of the declared age range, if available.
    let lowerBound: Int?
    /// Whether parental approval is required for significant app changes.
    let significantAppChangeApprovalRequired: Bool
}

/// Abstraction over DeclaredAgeRange APIs for testability.
protocol AgeRangeProviding {
    func requestAgeRange(
        minimumAge: Int,
        in viewController: UIViewController
    ) async throws -> AgeRangeSnapshot

    func isEligibleForAgeFeatures() async throws -> Bool
}

enum AgeRangeProviderError: Error {
    case declinedSharing
    case notAvailable
    case unknown
    case other(Error)
}

#if canImport(DeclaredAgeRange)
/// Real adapter for DeclaredAgeRange (iOS 26+).
final class DeclaredAgeRangeProvider: AgeRangeProviding {
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

    func isEligibleForAgeFeatures() async throws -> Bool {
        guard #available(iOS 26.2, *) else {
            throw AgeRangeProviderError.notAvailable
        }
        do {
            return try await AgeRangeService.shared.isEligibleForAgeFeatures
        } catch {
            throw AgeRangeProviderError.other(error)
        }
    }
}
#else
/// Fallback adapter when DeclaredAgeRange is unavailable.
final class DeclaredAgeRangeProvider: AgeRangeProviding {
    func requestAgeRange(
        minimumAge: Int,
        in viewController: UIViewController
    ) async throws -> AgeRangeSnapshot {
        throw AgeRangeProviderError.notAvailable
    }

    func isEligibleForAgeFeatures() async throws -> Bool {
        throw AgeRangeProviderError.notAvailable
    }
}
#endif
