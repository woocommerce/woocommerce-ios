import Foundation
import Yosemite

final class ULAccountMatcher {
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

        return sites
            .map{ $0.url }
            .contains(originalURL)
    }

    private func refreshResults() {
        try? resultsController.performFetch()
    }
}
