import Experiments
import Yosemite

protocol BookingsTabEligibilityCheckerProtocol {
    /// Checks the final visibility of the Bookings tab.
    func checkVisibility() async -> Bool
}

final class BookingsTabEligibilityChecker: BookingsTabEligibilityCheckerProtocol {
    private let site: Site
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    init(site: Site,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.site = site
        self.stores = stores
        self.featureFlagService = featureFlagService
    }

    /// Checks the final visibility of the Bookings tab.
    func checkVisibility() async -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.ciabBookings) else {
            return false
        }

        if await checkIfStoreHasBookableProducts() {
            return true
        } else if await checkIfStoreHasBookings() {
            return true
        } else {
            return false
        }
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
