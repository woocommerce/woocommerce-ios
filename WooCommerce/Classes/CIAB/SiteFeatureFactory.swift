import Foundation
import Storage
import Yosemite

/// The single branching point for site-type-based feature composition.
///
/// Everything downstream receives pre-decided providers. Adding a new site type
/// means adding a `case` to `SiteType` and a branch in each `switch` — the
/// compiler enforces exhaustiveness.
///
enum SiteFeatureFactory {

    /// Builds all synchronous providers for the given site.
    ///
    /// Called on every site switch. Resolves immediately — no async work.
    ///
    static func makeProviders(
        for site: Yosemite.Site?,
        storageManager: StorageManagerType = ServiceLocator.storageManager
    ) -> SiteFeatureProviders {
        let siteType = site.map(SiteType.init) ?? .standard

        return SiteFeatureProviders(
            dashboardCards: makeDashboardCardProvider(siteType: siteType),
            creatableProductTypes: makeCreatableProductTypeProvider(
                siteType: siteType,
                siteID: site?.siteID ?? 0,
                storageManager: storageManager
            ),
            filterableProductTypes: makeFilterableProductTypeProvider(
                siteType: siteType,
                siteID: site?.siteID ?? 0,
                storageManager: storageManager
            ),
            orderStatusEditing: makeOrderStatusEditingProvider(siteType: siteType),
            shipmentSplitting: makeShipmentSplittingProvider(siteType: siteType),
            productRouting: makeProductRoutingProvider(siteType: siteType)
        )
    }

    // MARK: - Individual Provider Factories

    private static func makeDashboardCardProvider(siteType: SiteType) -> DashboardCardProviding {
        switch siteType {
        case .standard:
            StandardDashboardCardProvider()
        case .ciab:
            CIABDashboardCardProvider()
        }
    }

    private static func makeCreatableProductTypeProvider(
        siteType: SiteType,
        siteID: Int64,
        storageManager: StorageManagerType
    ) -> CreatableProductTypeProviding {
        switch siteType {
        case .standard:
            StandardCreatableProductTypeProvider(
                subscriptionEligibility: WooSubscriptionProductsEligibilityChecker(
                    siteID: siteID,
                    storage: storageManager
                )
            )
        case .ciab:
            CIABCreatableProductTypeProvider()
        }
    }

    private static func makeFilterableProductTypeProvider(
        siteType: SiteType,
        siteID: Int64,
        storageManager: StorageManagerType
    ) -> FilterableProductTypeProviding {
        switch siteType {
        case .standard:
            StandardFilterableProductTypeProvider(
                activePlugins: fetchActivePlugins(siteID: siteID, storageManager: storageManager)
            )
        case .ciab:
            CIABFilterableProductTypeProvider()
        }
    }

    private static func makeOrderStatusEditingProvider(siteType: SiteType) -> OrderStatusEditingProviding {
        switch siteType {
        case .standard:
            StandardOrderStatusEditingProvider()
        case .ciab:
            CIABOrderStatusEditingProvider()
        }
    }

    private static func makeShipmentSplittingProvider(siteType: SiteType) -> ShipmentSplittingProviding {
        switch siteType {
        case .standard:
            StandardShipmentSplittingProvider()
        case .ciab:
            CIABShipmentSplittingProvider()
        }
    }

    private static func makeProductRoutingProvider(siteType: SiteType) -> ProductRoutingProviding {
        switch siteType {
        case .standard:
            StandardProductRoutingProvider()
        case .ciab:
            CIABProductRoutingProvider()
        }
    }

    // MARK: - Helpers

    private static func fetchActivePlugins(siteID: Int64, storageManager: StorageManagerType) -> [Plugin] {
        let predicate = NSPredicate(format: "siteID == %lld AND active == YES", siteID)
        let resultsController = ResultsController<StorageSystemPlugin>(storageManager: storageManager, sortedBy: [])
        resultsController.predicate = predicate
        try? resultsController.performFetch()
        return resultsController.fetchedObjects.compactMap { Plugin(systemPlugin: $0) }
    }
}
