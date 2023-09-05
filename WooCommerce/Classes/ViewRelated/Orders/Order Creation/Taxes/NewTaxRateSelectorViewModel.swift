import Foundation
import Yosemite
import Combine
import Storage

final class NewTaxRateSelectorViewModel: ObservableObject {
    private let wpAdminTaxSettingsURLProvider: WPAdminTaxSettingsURLProviderProtocol
    private let stores: StoresManager
    private let siteID: Int64
    private var subscriptions = Set<AnyCancellable>()

    /// Supports infinite scroll.
    private let paginationTracker: PaginationTracker

    /// Storage to fetch tax rates
    private let storageManager: StorageManagerType

    @Published private(set) var taxRateViewModels: [TaxRateViewModel] = []

    /// Current sync status; used to determine the view state.
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    /// Trigger to perform any one time setups.
    let onLoadTrigger: PassthroughSubject<Void, Never> = PassthroughSubject()

    /// View models for placeholder rows.
    let placeholderRowViewModels: [TaxRateViewModel] = [Int64](0..<3).map { index in
        TaxRateViewModel(id: index, name: "placeholder", rate: "10%")
    }

    init(siteID: Int64,
         wpAdminTaxSettingsURLProvider: WPAdminTaxSettingsURLProviderProtocol = WPAdminTaxSettingsURLProvider(),
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.wpAdminTaxSettingsURLProvider = wpAdminTaxSettingsURLProvider
        self.stores = stores
        self.storageManager = storageManager
        self.paginationTracker = PaginationTracker(pageFirstIndex: 1, pageSize: 25)

        configureResultsController()
        configurePaginationTracker()
        configureFirstPageLoad()
    }

    /// WPAdmin URL to navigate user to edit the tax settings
    var wpAdminTaxSettingsURL: URL? {
        wpAdminTaxSettingsURLProvider.provideWpAdminTaxSettingsURL()
    }

    /// Inbox notes ResultsController.
    private lazy var resultsController: ResultsController<StorageTaxRate> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageTaxRate.id, ascending: true)
        let resultsController = ResultsController<StorageTaxRate>(storageManager: storageManager,
                                                                    matching: predicate,
                                                                    sortedBy: [ sortDescriptorByID])
        return resultsController
    }()

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

extension NewTaxRateSelectorViewModel: PaginationTrackerDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        transitionToSyncingState()

        let action = TaxAction.retrieveTaxRates(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let results):
                let hasNextPage = results.count == pageSize
                onCompletion?(.success(hasNextPage))

                if taxRateViewModels.isEmpty {
                    self.syncState = .empty
                } else if results.isEmpty {
                    // We had results previously, but we didn't have any on this page request. Transition to results to stop the syncing visuals.
                    transitionToResultsUpdatedState()
                }
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing tax rates: \(error)")
                onCompletion?(.failure(error))
            }
        }
        stores.dispatch(action)
    }
}

private extension NewTaxRateSelectorViewModel {
    func configurePaginationTracker() {
        paginationTracker.delegate = self
    }

    func configureFirstPageLoad() {
        // Listens only to the first emitted event.
        onLoadTrigger.first()
            .sink { [weak self] in
                guard let self = self else { return }
                self.syncFirstPage()
            }
            .store(in: &subscriptions)
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
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    /// Updates row view models and sync state.
    func updateResults() {
        taxRateViewModels = resultsController.fetchedObjects.map { TaxRateViewModel(id: $0.id, name: $0.name, rate: $0.rate) }
        transitionToResultsUpdatedState()
    }

    func syncFirstPage() {
        paginationTracker.syncFirstPage()
    }
}

// MARK: - State Machine

extension NewTaxRateSelectorViewModel {
    /// Represents possible states for syncing inbox notes.
    enum SyncState: Equatable {
        case syncingFirstPage
        case results
        case empty
    }

    /// Update states for sync from remote.
    func transitionToSyncingState() {
        shouldShowBottomActivityIndicator = true
        if taxRateViewModels.isEmpty {
            syncState = .syncingFirstPage
        }
    }

    /// Update states after sync is complete.
    func transitionToResultsUpdatedState() {
        shouldShowBottomActivityIndicator = false
        syncState = taxRateViewModels.isNotEmpty ? .results: .empty
    }
}
