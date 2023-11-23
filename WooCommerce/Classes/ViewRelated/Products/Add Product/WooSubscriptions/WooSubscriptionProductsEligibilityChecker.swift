import Foundation
import protocol Storage.StorageManagerType
import Yosemite
import WooFoundation

/// Protocol for checking Woo Subscription Products eligibility for easier unit testing.
protocol WooSubscriptionProductsEligibilityCheckerProtocol {
    func isSiteEligible() -> Bool
}

/// Checks eligibility for adding Woo Subscription products
final class WooSubscriptionProductsEligibilityChecker: WooSubscriptionProductsEligibilityCheckerProtocol {
    private let siteID: Int64
    private let storage: StorageManagerType

    private lazy var resultsController: ResultsController<StorageSystemPlugin> = {
        let predicate = \StorageSystemPlugin.siteID == siteID && \StorageSystemPlugin.active == true
        let resultsController = ResultsController<StorageSystemPlugin>(storageManager: storage, sortedBy: [])
        resultsController.predicate = predicate
        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching Woo Subscription plugin details!")
        }
        return resultsController
    }()

    init(siteID: Int64,
         storage: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.storage = storage
    }

    /// Checks if the site is eligible for adding Woo Subscription products.
    ///
    func isSiteEligible() -> Bool {
        return isWooSubscriptionsPluginActive()
    }
}

private extension WooSubscriptionProductsEligibilityChecker {
    func isWooSubscriptionsPluginActive() -> Bool {
        let activePluginNames = resultsController.fetchedObjects
            .map { $0.name }
        return Set(activePluginNames).intersection(SitePlugin.SupportedPlugin.WCSubscriptions).count > 0
    }
}
