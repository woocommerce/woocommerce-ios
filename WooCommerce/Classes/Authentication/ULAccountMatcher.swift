import Foundation
import Yosemite

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

    init() {

    }


    func match(originalURL: String) -> Bool {
        refreshResults()

        print("==== sites ", sites)
        print("==== originalURL ", originalURL)

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
