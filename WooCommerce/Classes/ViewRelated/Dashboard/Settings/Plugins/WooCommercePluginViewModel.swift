import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class WooCommercePluginViewModel {

    /// ID of the site to load plugins for
    ///
    private let siteID: Int64

    /// Reference to the StoresManager to dispatch Yosemite Actions.
    ///
    private let storesManager: StoresManager

    /// StorageManager to load plugins from storage
    ///
    private let storageManager: StorageManagerType

    /// Results controller for the plugin list
    ///
    private lazy var resultsController: ResultsController<StorageSitePlugin> = {
        let predicate = NSPredicate(format: "siteID = %ld AND plugin = %@", self.siteID, "woocommerce/woocommerce")
        let resultsController = ResultsController<StorageSitePlugin>(
            storageManager: storageManager,
            matching: predicate,
            sortedBy: []
        )

        do {
            try resultsController.performFetch()
            woocommercePlugin = resultsController.fetchedObjects.first
        } catch {
            DDLogError("⛔️ Error fetching WooCommerce plugin details!")
        }
        return resultsController
    }()

    var woocommercePlugin: SitePlugin?

    init(siteID: Int64,
         storesManager: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.storesManager = storesManager
        self.storageManager = storageManager
        observeWooCommercePlugin { self.woocommercePlugin = self.resultsController.fetchedObjects.first }
    }

    /// Start fetching and observing plugin data from local storage.
    ///
    func observeWooCommercePlugin(onDataChanged: @escaping () -> Void) {
        resultsController.onDidChangeContent = onDataChanged
    }

    /// Manually sync plugins.
    ///
    func syncPlugins(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let action = SitePluginAction.synchronizeSitePlugins(siteID: siteID, onCompletion: onCompletion)
        storesManager.dispatch(action)
    }
}
