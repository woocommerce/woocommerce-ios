// periphery:ignore:all
import Foundation
import Yosemite
import Experiments

protocol BookingsTabEligibilityCheckerProtocol {
    /// Checks the initial visibility of the Bookings tab.
    func checkInitialVisibility() -> Bool
    /// Checks the final visibility of the Bookings tab.
    func checkVisibility() async -> Bool
}

final class BookingsTabEligibilityChecker: BookingsTabEligibilityCheckerProtocol {
    private let site: Site
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let ciabEligibilityChecker: CIABEligibilityCheckerProtocol
    private let userDefaults: UserDefaults

    init(site: Site,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         ciabEligibilityChecker: CIABEligibilityCheckerProtocol = CIABEligibilityChecker(),
         userDefaults: UserDefaults = .standard) {
        self.site = site
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.ciabEligibilityChecker = ciabEligibilityChecker
        self.userDefaults = userDefaults
    }

    /// Checks the initial visibility of the Bookings tab using cached result.
    func checkInitialVisibility() -> Bool {
        userDefaults.loadCachedBookingsTabVisibility(siteID: site.siteID)
    }

    /// Checks the final visibility of the Bookings tab.
    func checkVisibility() async -> Bool {
        // Check feature flag
        guard featureFlagService.isFeatureFlagEnabled(.ciabBookings) else {
            return false
        }

        // Check if current site is NOT CIAB (bookings only for non-CIAB sites)
        guard ciabEligibilityChecker.isSiteCIAB(site) else {
            return false
        }

        // Cache the result
        let isVisible = await checkIfStoreHasBookableProducts()
        userDefaults.cacheBookingsTabVisibility(siteID: site.siteID, isVisible: isVisible)

        return isVisible
    }
}

// MARK: Private helpers
//
private extension BookingsTabEligibilityChecker {
    @MainActor
    func checkIfStoreHasBookableProducts() async -> Bool {
        await withCheckedContinuation { continuation in
            stores.dispatch(ProductAction.checkIfStoreHasProducts(siteID: site.siteID, type: .booking) { result in
                let hasBookableProducts = (try? result.get()) ?? false
                continuation.resume(returning: hasBookableProducts)
            })
        }
    }
}

extension UserDefaults {
    func loadCachedBookingsTabVisibility(siteID: Int64) -> Bool {
        guard let cachedValue = self[.ciabBookingsTabAvailable] as? [String: Bool],
              let availability = cachedValue[siteID.description] else {
            return false
        }
        return availability
    }

    func cacheBookingsTabVisibility(siteID: Int64, isVisible: Bool) {
        var cache = (self[.ciabBookingsTabAvailable] as? [String: Bool]) ?? [:]
        cache[siteID.description] = isVisible
        self[.ciabBookingsTabAvailable] = cache
    }
}
