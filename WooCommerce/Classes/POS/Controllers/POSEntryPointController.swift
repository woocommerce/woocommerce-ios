import SwiftUI
import protocol Experiments.FeatureFlagService

@available(iOS 17.0, *)
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
