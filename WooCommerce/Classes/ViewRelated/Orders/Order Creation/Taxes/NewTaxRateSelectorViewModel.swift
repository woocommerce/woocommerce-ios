import Foundation
import Yosemite
import Combine
import Storage
import Experiments
import protocol WooFoundation.Analytics

final class NewTaxRateSelectorViewModel: ObservableObject {
    private let wpAdminTaxSettingsURLProvider: WPAdminTaxSettingsURLProviderProtocol
    private let stores: StoresManager
    private let siteID: Int64
    private var subscriptions = Set<AnyCancellable>()

    /// Supports infinite scroll.
    private let paginationTracker: PaginationTracker

    /// Storage to fetch tax rates
    private let storageManager: StorageManagerType

    /// Analytics engine.
    ///
    private let analytics: Analytics

    private let featureFlagService: FeatureFlagService

    @Published private(set) var taxRateViewModels: [TaxRateViewModel] = []

    /// Current sync status; used to determine the view state.
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    /// Trigger to perform any one time setups.
    let onLoadTriggerOnce: PassthroughSubject<Void, Never> = PassthroughSubject()

    let onTaxRateSelected: (Yosemite.TaxRate) -> Void

    /// View models for placeholder rows. Strings are visible to the user as it is shimmering (loading)
    let placeholderRowViewModels: [TaxRateViewModel] = [Int64](0..<3).map { index in
        TaxRateViewModel(id: index, title: "placeholder", rate: "10%", showChevron: true)
    }

    init(siteID: Int64,
         onTaxRateSelected: @escaping (Yosemite.TaxRate) -> Void,
         wpAdminTaxSettingsURLProvider: WPAdminTaxSettingsURLProviderProtocol = WPAdminTaxSettingsURLProvider(),
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.onTaxRateSelected = onTaxRateSelected
        self.wpAdminTaxSettingsURLProvider = wpAdminTaxSettingsURLProvider
        self.stores = stores
        self.storageManager = storageManager
        self.paginationTracker = PaginationTracker(pageFirstIndex: 1, pageSize: 25)
        self.analytics = analytics
        self.featureFlagService = featureFlagService

        configureResultsController()
        configurePaginationTracker()
        configureFirstPageLoad()
    }

    /// WPAdmin URL to navigate user to edit the tax settings
    var wpAdminTaxSettingsURL: URL? {
        wpAdminTaxSettingsURLProvider.provideWpAdminTaxSettingsURL()
    }

    private lazy var resultsController: ResultsController<StorageTaxRate> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageTaxRate.order, ascending: true)
        let resultsController = ResultsController<StorageTaxRate>(storageManager: storageManager,
                                                                    matching: predicate,
                                                                    sortedBy: [ sortDescriptorByID])
        return resultsController
    }()

    func onLoadNextPageAction() {
        paginationTracker.ensureNextPageIsSynced()
    }

    func onRowSelected(with index: Int, storeSelectedTaxRate: Bool) {
        analytics.track(.taxRateSelectorTaxRateTapped, withProperties: ["auto_tax_rate_enabled": storeSelectedTaxRate])

        guard let taxRateViewModel = taxRateViewModels[safe: index],
              let taxRate = resultsController.fetchedObjects.first(where: { $0.id == taxRateViewModel.id }) else {
            return
        }

        if storeSelectedTaxRate {
            stores.dispatch(AppSettingsAction.setSelectedTaxRateID(id: taxRate.id, siteID: siteID))
        }

        onTaxRateSelected(taxRate)
    }

    func onRefreshAction() {
        taxRateViewModels = []
        transitionToSyncingState()
        paginationTracker.resync(reason: nil)
    }

    func onShowWebView() {
        analytics.track(.taxRateSelectorEditInAdminTapped)
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

                if self.taxRateViewModels.isEmpty {
                    self.syncState = .empty
                } else if results.isEmpty {
                    // We had results previously, but we didn't have any on this page request. Transition to results to stop the syncing visuals.
                    self.transitionToResultsUpdatedState()
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
        onLoadTriggerOnce.first()
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
        taxRateViewModels = resultsController.fetchedObjects
        .filter {
            $0.hasAddress
        }
        .map {
            TaxRateViewModel(taxRate: $0)
        }
        transitionToResultsUpdatedState()
    }

    func syncFirstPage() {
        paginationTracker.syncFirstPage()
    }
}

// MARK: - State Machine

extension NewTaxRateSelectorViewModel {
    enum SyncState: Equatable {
        case syncingFirstPage
        case results
        case empty
    }

    func transitionToSyncingState() {
        shouldShowBottomActivityIndicator = true
        if taxRateViewModels.isEmpty {
            syncState = .syncingFirstPage
        }
    }

    func transitionToResultsUpdatedState() {
        shouldShowBottomActivityIndicator = false
        syncState = taxRateViewModels.isNotEmpty ? .results: .empty
    }
}

private extension Yosemite.TaxRate {
    var hasAddress: Bool {
        city.isNotEmpty || cities.isNotEmpty || postcodes.isNotEmpty || postcodes.isNotEmpty || state.isNotEmpty || country.isNotEmpty
    }
}
