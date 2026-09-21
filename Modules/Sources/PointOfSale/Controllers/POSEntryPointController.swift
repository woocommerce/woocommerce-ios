import SwiftUI

public protocol POSEntryPointEligibilityCheckerProtocol {
    /// Eligibility drives UI-owned entry-point state, so callers must access the checker from the main actor.
    /// Determines whether the site is eligible for POS.
    /// - Parameter forceRemoteCheck: When true, skips locally available positive state and re-validates
    ///   remotely, so background refreshes can detect a store that became ineligible. Entry paths pass
    ///   false to enter from local state without waiting on remote checks.
    @MainActor
    func checkEligibility(forceRemoteCheck: Bool) async -> POSEligibilityState
    /// Refreshes the eligibility state based on the provided ineligible reason.
    @MainActor
    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState
}

@MainActor
@Observable final class POSEntryPointController {
    private(set) var eligibilityState: POSEligibilityState?
    private let posEligibilityChecker: POSEntryPointEligibilityCheckerProtocol

    init(eligibilityChecker: POSEntryPointEligibilityCheckerProtocol) {
        self.posEligibilityChecker = eligibilityChecker

        Task { @MainActor in
            eligibilityState = await posEligibilityChecker.checkEligibility(forceRemoteCheck: false)
        }
    }

    func refreshEligibility(reason: POSIneligibleReason) async throws {
        eligibilityState = try await posEligibilityChecker.refreshEligibility(ineligibleReason: reason)
    }
}
