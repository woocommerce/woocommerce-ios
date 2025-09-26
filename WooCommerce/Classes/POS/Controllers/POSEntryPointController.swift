import SwiftUI

public protocol POSEntryPointEligibilityCheckerProtocol {
    /// Determines whether the site is eligible for POS.
    func checkEligibility() async -> POSEligibilityState
    /// Refreshes the eligibility state based on the provided ineligible reason.
    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState
}

@Observable final class POSEntryPointController {
    private(set) var eligibilityState: POSEligibilityState?
    private let posEligibilityChecker: POSEntryPointEligibilityCheckerProtocol

    init(eligibilityChecker: POSEntryPointEligibilityCheckerProtocol) {
        self.posEligibilityChecker = eligibilityChecker

        Task { @MainActor in
            eligibilityState = await posEligibilityChecker.checkEligibility()
        }
    }

    @MainActor
    func refreshEligibility(reason: POSIneligibleReason) async throws {
        eligibilityState = try await posEligibilityChecker.refreshEligibility(ineligibleReason: reason)
    }
}
