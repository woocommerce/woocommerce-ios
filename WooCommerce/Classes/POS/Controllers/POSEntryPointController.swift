import SwiftUI
import protocol Experiments.FeatureFlagService

public protocol POSEntryPointEligibilityCheckerProtocol {
    /// Checks the initial visibility of the POS tab.
    func checkInitialVisibility() -> Bool
    /// Checks the final visibility of the POS tab.
    func checkVisibility() async -> Bool
    /// Determines whether the site is eligible for POS.
    func checkEligibility() async -> POSEligibilityState
    /// Refreshes the eligibility state based on the provided ineligible reason.
    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState
}

@Observable final class POSEntryPointController {
    private(set) var eligibilityState: POSEligibilityState?
    private let posEligibilityChecker: POSEntryPointEligibilityCheckerProtocol
    private let featureFlagService: POSFeatureFlagProviding

    init(eligibilityChecker: POSEntryPointEligibilityCheckerProtocol,
         featureFlagService: POSFeatureFlagProviding) {
        self.posEligibilityChecker = eligibilityChecker
        self.featureFlagService = featureFlagService

        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleAsATabi2) else {
            self.eligibilityState = .eligible
            return
        }
        Task { @MainActor in
            eligibilityState = await posEligibilityChecker.checkEligibility()
        }
    }

    @MainActor
    func refreshEligibility(reason: POSIneligibleReason) async throws {
        eligibilityState = try await posEligibilityChecker.refreshEligibility(ineligibleReason: reason)
    }
}
