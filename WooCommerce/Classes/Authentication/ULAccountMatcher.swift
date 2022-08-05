import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// Used to match a site address with a wordpress.com account, as part
/// of the Unified Login process
final class ULAccountMatcher {
    private let wpComURL = "https://wordpress.com"
    /// ResultsController: Loads all Sites from the Storage Layer.
    ///
    private lazy var resultsController: ResultsController<StorageSite> = {
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        return ResultsController(storageManager: storageManager, sortedBy: [descriptor])
    }()

    private var sites: [Site] {
        resultsController.fetchedObjects
    }

    private let storageManager: StorageManagerType

    init(storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.storageManager = storageManager
    }

    /// Checks if the user has any site that has WooCommerce.
    ///
    var hasConnectedStores: Bool {
        sites.first(where: { $0.isWooCommerceActive }) != nil
    }

    /// Checks if the URL passed as parameter is one of the sites
    /// saved in Storage
    /// - Parameter originalURL: a store address
    /// - Returns: a boolean indicating if the url passed as parameter is already saved
    func match(originalURL: String) -> Bool {

        /// When loggin in with a wp.com account, WPAuthenticator will set the
        /// account's blog URL to be `https://wordpress.com`
        /// We want to move forward and allow the login for those.
        guard originalURL != wpComURL else {
            return true
        }

        return sites
            .map { $0.url }
            .contains(originalURL)
    }

    /// Returns a locally stored site that matches the given site URL.
    /// - Parameter originalURL: a site address.
    /// - Returns: a locally stored `Site` that matches the given site URL. If there is no match, `nil` is returned.
    func matchedSite(originalURL: String) -> Site? {

        /// When logging in with a wp.com account, WPAuthenticator will set the
        /// account's blog URL to be `https://wordpress.com`
        /// We want to return `nil` in this case.
        guard originalURL != wpComURL else {
            return nil
        }

        return sites.first { $0.url == originalURL }
    }

    /// Refreshes locally stored sites that were synced previously.
    func refreshStoredSites() {
        try? resultsController.performFetch()
    }
}
