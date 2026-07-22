import SwiftUI

public protocol POSEntryPointEligibilityCheckerProtocol {
    /// Determines whether the site is eligible for POS.
    /// - Parameter forceRemoteCheck: When true, skips locally available positive state and re-validates
    ///   remotely, so background refreshes can detect a store that became ineligible. Entry paths pass
    ///   false to enter from local state without waiting on remote checks.
    func checkEligibility(forceRemoteCheck: Bool) async -> POSEligibilityState
    /// Refreshes the eligibility state based on the provided ineligible reason.
    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState
}

@Observable final class POSEntryPointController {
    private(set) var eligibilityState: POSEligibilityState?
    private let posEligibilityChecker: POSEntryPointEligibilityCheckerProtocol

    init(eligibilityChecker: POSEntryPointEligibilityCheckerProtocol) {
        self.posEligibilityChecker = eligibilityChecker

        Task { @MainActor in
            eligibilityState = await posEligibilityChecker.checkEligibility(forceRemoteCheck: false)
        }
    }

    @MainActor
    func refreshEligibility(reason: POSIneligibleReason) async throws {
        eligibilityState = try await posEligibilityChecker.refreshEligibility(ineligibleReason: reason)
    }
}
