import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// Conformance to support listing in SwiftUI
extension BlazeCampaign: Identifiable {
    public var id: Int64 {
        campaignID
    }
}

/// View model for `BlazeCampaignListView`
final class BlazeCampaignListViewModel: ObservableObject {
    @Published private(set) var items: [BlazeCampaign] = []

    private let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics

    /// Keeps track of the current state of the syncing
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    /// Supports infinite scroll.
    private let paginationTracker: PaginationTracker
    private let pageFirstIndex: Int = PaginationTracker.Defaults.pageFirstIndex

    /// Blaze campaign ResultsController.
    private lazy var resultsController: ResultsController<StorageBlazeCampaign> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageBlazeCampaign.campaignID, ascending: true)
        let resultsController = ResultsController<StorageBlazeCampaign>(storageManager: storageManager,
                                                                        matching: predicate,
                                                                        sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
        self.paginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex)

        configureResultsController()
        configurePaginationTracker()
    }

    func loadCampaigns() {
        paginationTracker.syncFirstPage()
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

// MARK: Configuration

private extension BlazeCampaignListViewModel {
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
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    /// Updates row view models and sync state.
    func updateResults() {
        items = resultsController.fetchedObjects
        transitionToResultsUpdatedState()
    }
}

extension BlazeCampaignListViewModel: PaginationTrackerDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        transitionToSyncingState()

        let action = BlazeAction.synchronizeCampaigns(siteID: siteID, pageNumber: pageNumber) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let hasNextPage):
                onCompletion?(.success(hasNextPage))

            case .failure(let error):
                DDLogError("⛔️ Error synchronizing Blaze campaigns: \(error)")
                onCompletion?(.failure(error))
            }
        }
        stores.dispatch(action)
    }
}

// MARK: State Machine

extension BlazeCampaignListViewModel {
    /// Represents possible states for syncing inbox notes.
    enum SyncState: Equatable {
        case syncingFirstPage
        case results
        case empty
    }

    /// Update states for sync from remote.
    func transitionToSyncingState() {
        shouldShowBottomActivityIndicator = true
        if items.isEmpty {
            syncState = .syncingFirstPage
        }
    }

    /// Update states after sync is complete.
    func transitionToResultsUpdatedState() {
        shouldShowBottomActivityIndicator = false
        syncState = items.isNotEmpty ? .results: .empty
    }
}