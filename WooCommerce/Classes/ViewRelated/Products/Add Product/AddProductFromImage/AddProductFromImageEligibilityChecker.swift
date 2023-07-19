import Foundation
import Yosemite
import protocol Experiments.FeatureFlagService
import Experiments

/// Protocol for checking "add product from image" eligibility for easier unit testing.
protocol AddProductFromImageEligibilityCheckerProtocol {
    /// Checks if the user is eligible to participate in the A/B experiment.
    func isEligibleToParticipateInABTest() -> Bool

    /// Checks if the user is eligible for the "add product from image" feature.
    func isEligible() -> Bool
}

/// Checks the eligibility for the "add product from image" feature.
final class AddProductFromImageEligibilityChecker: AddProductFromImageEligibilityCheckerProtocol {
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let abTestVariationProvider: ABTestVariationProvider

    init(stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         abTestVariationProvider: ABTestVariationProvider = DefaultABTestVariationProvider()) {
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.abTestVariationProvider = abTestVariationProvider
    }

    func isEligibleToParticipateInABTest() -> Bool {
        stores.sessionManager.defaultSite?.isWordPressComStore == true
    }

    func isEligible() -> Bool {
        // `isEligibleToParticipateInABTest` isn't necessary here since `isEligibleToParticipateInABTest` is
        // checked before this in its use case, but it's still included here so that it remains a condition when
        // removing the A/B experiment.
        guard isEligibleToParticipateInABTest() else {
            return false
        }

        guard featureFlagService.isFeatureFlagEnabled(.addProductFromImage) else {
            return false
        }

        return abTestVariationProvider.variation(for: .addProductFromImage) == .treatment
    }
}
