import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class CustomersListViewModel: ObservableObject {

    /// Customers to display in customer list.
    @Published private(set) var customers: [WCAnalyticsCustomer] = []

    // MARK: Sync

    /// Current sync status; used to determine the view state.
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    // MARK: Private properties

    private let siteID: Int64

    /// Supports infinite scroll.
    private let paginationTracker: PaginationTracker
    private let pageFirstIndex: Int = PaginationTracker.Defaults.pageFirstIndex

    /// Stores to sync customers.
    private let stores: StoresManager

    /// Storage to fetch customer list.
    private let storageManager: StorageManagerType

    /// Customers ResultsController.
    private lazy var resultsController: ResultsController<StorageWCAnalyticsCustomer> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptor = NSSortDescriptor(keyPath: \StorageWCAnalyticsCustomer.dateLastActive, ascending: false)
        return ResultsController<StorageWCAnalyticsCustomer>(storageManager: storageManager, matching: predicate, sortedBy: [sortDescriptor])
    }()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.paginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex)

        configureResultsController()
        configurePaginationTracker()
    }

    /// Returns the given customer name, formatted for display.
    func displayName(for customer: WCAnalyticsCustomer) -> String {
        guard let name = customer.name, name.trimmingCharacters(in: .whitespaces).isNotEmpty else {
            return Localization.guestLabel
        }
        return name
    }

    /// Returns the given customer username for display, if available.
    func displayUsername(for customer: WCAnalyticsCustomer) -> String? {
        guard let username = customer.username, username.isNotEmpty else {
            return nil
        }
        return username
    }

    /// Returns the given customer email for display, if available.
    func displayEmail(for customer: WCAnalyticsCustomer) -> String? {
        guard let email = customer.email, email.isNotEmpty else {
            return nil
        }
        return email
    }

    /// Called when the next page should be loaded.
    func onLoadNextPageAction() {
        paginationTracker.ensureNextPageIsSynced()
    }

    /// Called when the user pulls down the list to refresh.
    /// - Parameter completion: called when the refresh completes.
    func onRefreshAction(completion: @escaping () -> Void) {
        paginationTracker.resync(reason: nil) {
            completion()
        }
    }
}

// MARK: - Remote Sync

extension CustomersListViewModel: PaginationTrackerDelegate {
    /// Syncs the first page of customers from remote.
    func loadCustomers() {
        paginationTracker.syncFirstPage()
    }

    /// Syncs the given page of customers from remote.
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        transitionToSyncingState()
        let action = CustomerAction.synchronizeAllCustomers(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(hasNextPage):
                onCompletion?(.success(hasNextPage))
            case let .failure(error):
                DDLogError("⛔️ Error synchronizing customers: \(error)")
                onCompletion?(.failure(error))
            }
            self.updateResults()
        }
        stores.dispatch(action)
    }
}

// MARK: - Configuration

private extension CustomersListViewModel {
    /// Configures pagination tracker for infinite scroll.
    func configurePaginationTracker() {
        paginationTracker.delegate = self
    }

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
            updateResults()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    /// Updates customers and sync state.
    func updateResults() {
        customers = resultsController.fetchedObjects
        transitionToResultsUpdatedState()
    }
}

// MARK: - State Machine

extension CustomersListViewModel {
    /// Represents possible states for syncing customers list.
    enum SyncState: Equatable {
        case syncingFirstPage
        case results
        case empty
    }

    /// Update states for sync from remote.
    func transitionToSyncingState() {
        shouldShowBottomActivityIndicator = true
        if customers.isEmpty {
            syncState = .syncingFirstPage
        }
    }

    /// Update states after sync is complete.
    func transitionToResultsUpdatedState() {
        shouldShowBottomActivityIndicator = false
        syncState = customers.isNotEmpty ? .results: .empty
    }

    /// View models for placeholder rows.
    static let placeholderRows: [WCAnalyticsCustomer] = [Int64](0..<3).map {
        // The content does not matter because the text in placeholder rows is redacted.
        WCAnalyticsCustomer(siteID: 0,
                            customerID: $0,
                            userID: 0,
                            name: nil,
                            email: nil,
                            username: nil,
                            dateRegistered: nil,
                            dateLastActive: Date(),
                            ordersCount: 0,
                            totalSpend: 0,
                            averageOrderValue: 0,
                            country: "",
                            region: "",
                            city: "",
                            postcode: "")
    }
}

private extension CustomersListViewModel {
    enum Localization {
        static let guestLabel = NSLocalizedString("customersList.guestLabel",
                                                  value: "Guest",
                                                  comment: "Label for a customer with no name in the Customers list screen.")
    }
}
