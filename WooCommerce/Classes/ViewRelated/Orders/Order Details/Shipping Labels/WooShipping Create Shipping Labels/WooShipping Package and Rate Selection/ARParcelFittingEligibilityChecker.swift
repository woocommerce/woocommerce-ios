import ARKit
import Experiments
import Foundation
import Yosemite

protocol ARParcelFittingEligibilityChecking {
    @MainActor
    func isEligible() async -> Bool
}

struct ARParcelFittingEligibilityChecker: ARParcelFittingEligibilityChecking {
    private let featureFlagService: FeatureFlagService
    private let abTestVariationProvider: ABTestVariationProvider
    private let remoteFeatureFlagService: RemoteFeatureFlagServiceProtocol
    private let isARWorldTrackingSupported: Bool

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         abTestVariationProvider: ABTestVariationProvider = DefaultABTestVariationProvider(),
         stores: StoresManager = ServiceLocator.stores,
         isARWorldTrackingSupported: Bool = ARWorldTrackingConfiguration.isSupported) {
        self.featureFlagService = featureFlagService
        self.abTestVariationProvider = abTestVariationProvider
        self.remoteFeatureFlagService = RemoteFeatureFlagService(stores: stores)
        self.isARWorldTrackingSupported = isARWorldTrackingSupported
    }

    /// Resolves AR parcel fitting availability:
    /// ARSupported AND localFF AND (remoteFF OR ExPlat).
    @MainActor
    func isEligible() async -> Bool {
        guard isARWorldTrackingSupported else {
            return false
        }
        guard featureFlagService.isFeatureFlagEnabled(.arParcelFitting) else {
            return false
        }
        if abTestVariationProvider.variation(for: .arParcelFitting) == .treatment {
            return true
        }
        return await remoteFeatureFlagService.isEnabled(.arParcelFitting, defaultValue: false)
    }
}
