import Foundation
import Yosemite

/// Used to match a store address with a wordpress.com account, as part
/// of the Unified Login process
final class ULAccountMatcher {
    private let wpComURL = "https://wordpress.com"
    /// ResultsController: Loads Sites from the Storage Layer.
    ///
    private let resultsController: ResultsController<StorageSite> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "isWooCommerceActive == YES")
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    private var sites: [Site] {
        resultsController.fetchedObjects
    }


    /// Checks if the URL passed as parameter is one of the sites
    /// saved in Storage
    /// - Parameter originalURL: a store address
    /// - Returns: a boolean indicating if the url passed as parameter is already saved
    func match(originalURL: String) -> Bool {
        refreshResults()

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

    private func refreshResults() {
        try? resultsController.performFetch()
    }
}
