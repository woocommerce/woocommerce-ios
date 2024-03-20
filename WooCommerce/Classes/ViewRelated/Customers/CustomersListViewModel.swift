import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class CustomersListViewModel: ObservableObject {
    /// Customers to display in customer list.
    @Published private(set) var customers: [WCAnalyticsCustomer] = []

    private let siteID: Int64

    /// Storage to fetch customer list.
    private let storageManager: StorageManagerType

    /// Customers ResultsController.
    private lazy var resultsController: ResultsController<StorageWCAnalyticsCustomer> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptor = NSSortDescriptor(keyPath: \StorageWCAnalyticsCustomer.dateLastActive, ascending: false)
        return ResultsController<StorageWCAnalyticsCustomer>(storageManager: storageManager, matching: predicate, sortedBy: [sortDescriptor])
    }()

    init(siteID: Int64,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.storageManager = storageManager

        configureResultsController()
    }
}

// MARK: - Configuration

private extension CustomersListViewModel {
    /// Performs initial fetch from storage and updates results.
    func configureResultsController() {
        resultsController.onDidChangeContent = { [weak self] in
            self?.updateResults()
        }
        resultsController.onDidResetContent = { [weak self] in
            self?.updateResults()
        }

        do {
            try resultsController.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    /// Updates row view models and sync state.
    func updateResults() {
        customers = resultsController.fetchedObjects
    }
}
