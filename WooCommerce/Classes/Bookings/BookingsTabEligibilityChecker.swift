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
    private let userDefaults: UserDefaults

    init(site: Site,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         userDefaults: UserDefaults = .standard) {
        self.site = site
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.userDefaults = userDefaults
    }

    /// Checks the initial visibility of the Bookings tab using cached result.
    func checkInitialVisibility() -> Bool {
        userDefaults.loadCachedBookingsTabVisibility(siteID: site.siteID)
    }

    /// Checks the initial visibility without the `BookingsTabEligibilityChecker` instsance
    /// Used for the initial state check when a site instance hasn't been loaded but a `siteID` is available
    static func checkInitialVisibility(
        for siteID: Int64,
        in userDefaults: UserDefaults = .standard
    ) -> Bool {
        return userDefaults.loadCachedBookingsTabVisibility(siteID: siteID)
    }

    /// Checks the final visibility of the Bookings tab.
    func checkVisibility() async -> Bool {
        // Check feature flag
        guard featureFlagService.isFeatureFlagEnabled(.ciabBookings) else {
            return false
        }

        // Bookings are only available on CIAB sites
        guard SiteType(site: site) == .ciab else {
            return false
        }

        // Check if store has bookable products or bookings
        let isVisible: Bool = await {
            if await checkIfStoreHasBookableProducts() {
                return true
            } else if await checkIfStoreHasBookings() {
                return true
            } else {
                return false
            }
        }()

        // Cache the result
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

    @MainActor
    func checkIfStoreHasBookings() async -> Bool {
        await withCheckedContinuation { continuation in
            stores.dispatch(BookingAction.checkIfStoreHasBookings(siteID: site.siteID) { result in
                let hasBookings = (try? result.get()) ?? false
                continuation.resume(returning: hasBookings)
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
