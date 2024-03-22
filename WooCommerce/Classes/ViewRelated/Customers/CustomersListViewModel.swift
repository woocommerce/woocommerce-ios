import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import Combine

final class CustomersListViewModel: ObservableObject {

    /// Customers to display in customer list.
    @Published private(set) var customers: [WCAnalyticsCustomer] = []

    /// Current search term entered by the user.
    /// Each update will trigger a remote customer search and sync.
    @Published var searchTerm: String = ""

    /// Whether to show the advanced search.
    /// If `false`, search filters should be provided.
    @Published var showAdvancedSearch: Bool = false

    /// Current search filter selected by the user.
    /// Defaults to search the customer name (`name`).
    @Published var searchFilter: CustomerSearchFilter = .name

    /// Available filters for the customer search.
    let searchFilters: [CustomerSearchFilter] = [.name, .username, .email]

    /// Whether the search header should be displayed.
    var showSearchHeader: Bool {
        customers.isNotEmpty || searchTerm.isNotEmpty
    }

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
        let predicate = resultsPredicate
        let sortDescriptor = NSSortDescriptor(keyPath: \StorageWCAnalyticsCustomer.dateLastActive, ascending: false)
        return ResultsController<StorageWCAnalyticsCustomer>(storageManager: storageManager, matching: predicate, sortedBy: [sortDescriptor])
    }()

    /// Default predicate for the results controller.
    ///
    private lazy var resultsPredicate: NSPredicate? = {
        NSPredicate(format: "siteID == %lld", siteID)
    }()

    /// Store for publishers subscriptions
    ///
    private var subscriptions = Set<AnyCancellable>()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.paginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex)

        configureResultsController()
        configurePaginationTracker()
        configureSearchHeader()
        observeSearch()
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

    /// Called when a customer is selected.
    func trackCustomerSelected(_ customer: WCAnalyticsCustomer) {
        ServiceLocator.analytics.track(event: .CustomersHub.customerDetailOpened(registered: customer.userID != 0,
                                                                                 hasEmail: customer.email?.isNotEmpty == true))
    }
}

// MARK: - Remote Sync

extension CustomersListViewModel: PaginationTrackerDelegate {
    /// Syncs the first page of customers from remote.
    func loadCustomers() {
        paginationTracker.syncFirstPage()
    }

    /// Updates the customer results predicate & triggers a new sync when search term or filter changes
    ///
    func observeSearch() {
        let searchTermPublisher = $searchTerm
            .removeDuplicates()
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)

        let searchFilterPublisher = $searchFilter
            .removeDuplicates()
            .dropFirst()

        searchTermPublisher
            .combineLatest(searchFilterPublisher.prepend(searchFilter)) // Use configured filter as initial value
            .sink { [weak self] (searchTerm, searchFilter) in
                guard let self else { return }
                self.updatePredicate(searchTerm: searchTerm)
                self.updateResults()
                self.searchFilter = searchFilter // Ensure latest filter is used in remote search
                self.paginationTracker.resync()
            }.store(in: &subscriptions)
    }

    /// Syncs the given page of customers from remote.
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        transitionToSyncingState()
        if searchTerm.isEmpty {
            synchronizeAllCustomers(pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        } else {
            searchCustomers(keyword: searchTerm, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        }
    }

    /// Syncs all customers from remote.
    private func synchronizeAllCustomers(pageNumber: Int, pageSize: Int, onCompletion: SyncCompletion?) {
        let action = CustomerAction.synchronizeAllCustomers(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(hasNextPage):
                ServiceLocator.analytics.track(event: .CustomersHub.customerListLoaded())
                onCompletion?(.success(hasNextPage))
            case let .failure(error):
                DDLogError("⛔️ Error synchronizing customers: \(error)")
                ServiceLocator.analytics.track(event: .CustomersHub.customerListLoadFailed(withError: error))
                onCompletion?(.failure(error))
            }
            self.updateResults()
        }
        stores.dispatch(action)
    }

    /// Searches all customers from remote.
    private func searchCustomers(keyword: String, pageNumber: Int, pageSize: Int, onCompletion: SyncCompletion?) {
        ServiceLocator.analytics.track(event: .CustomersHub.customerListSearched(withFilter: searchFilter))
        let action = CustomerAction.searchWCAnalyticsCustomers(siteID: siteID,
                                                               pageNumber: pageNumber,
                                                               pageSize: pageSize,
                                                               keyword: keyword,
                                                               filter: searchFilter) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.updateResults()
            case let .failure(error):
                DDLogError("⛔️ Error searching customers: \(error)")
            }
            onCompletion?(result)
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

    /// Checks whether the store is eligible for searching all customer search filters at once.
    func configureSearchHeader() {
        isEligibleForAdvancedSearch { [weak self] isEligible in
            self?.searchFilter = isEligible ? .all : .name
            self?.showAdvancedSearch = isEligible
        }
    }

    /// Checks whether the store is eligible for searching all customer search filters at once.
    func isEligibleForAdvancedSearch(completion: @escaping (Bool) -> Void) {
        // Fetches WC plugin.
        let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: Constants.wcPluginName) { wcPlugin in
            guard let wcPlugin, wcPlugin.active else {
                return completion(false)
            }

            let isCustomerAdvanceSearchSupportedByWCPlugin = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                               minimumRequired: Constants.wcPluginMinimumVersion)
            completion(isCustomerAdvanceSearchSupportedByWCPlugin)
        }
        stores.dispatch(action)
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

    func updatePredicate(searchTerm: String) {
        if searchTerm.isNotEmpty {
            // When the search query changes, also includes the original results predicate in addition to the search keyword.
            let searchResultsPredicate = NSPredicate(format: "ANY searchResults.keyword = %@", searchTerm)
            let subpredicates = [resultsPredicate, searchResultsPredicate].compactMap { $0 }
            resultsController.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        } else {
            // Resets the results to the full customer list when there is no search query.
            resultsController.predicate = resultsPredicate
        }
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

// MARK: - Constants

private extension CustomersListViewModel {
    enum Localization {
        static let guestLabel = NSLocalizedString("customersList.guestLabel",
                                                  value: "Guest",
                                                  comment: "Label for a customer with no name in the Customers list screen.")
    }

    enum Constants {
        static let wcPluginName = "WooCommerce"
        static let wcPluginMinimumVersion = "8.0.0-beta.1"
    }
}
