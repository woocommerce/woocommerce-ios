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
    @Published private(set) var campaigns: [BlazeCampaign] = []
    @Published var shouldDisplayPostCampaignCreationTip = false
    @Published var shouldShowIntroView = false

    /// Tracks whether the intro view has been presented.
    private var didShowIntroView = false

    private let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let userDefaults: UserDefaults
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
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageBlazeCampaign.campaignID, ascending: false)
        let resultsController = ResultsController<StorageBlazeCampaign>(storageManager: storageManager,
                                                                        matching: predicate,
                                                                        sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         userDefaults: UserDefaults = .standard,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.userDefaults = userDefaults
        self.analytics = analytics
        self.paginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex)

        configureResultsController()
        configurePaginationTracker()
    }

    /// Called when loading the first page of campaigns.
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

    /// Called after a Blaze campaign is successfully created.
    ///
    func checkIfPostCreationTipIsNeeded() {
        let hasDisplayed = userDefaults.hasDisplayedTipAfterBlazeCampaignCreation(for: siteID)
        if !hasDisplayed {
            shouldDisplayPostCampaignCreationTip = true
            userDefaults.setBlazePostCreationTipAsDisplayed(for: siteID)
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
            updateResults()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    /// Updates row view models and sync state.
    func updateResults() {
        campaigns = resultsController.fetchedObjects
        transitionToResultsUpdatedState()
    }
}

extension BlazeCampaignListViewModel: PaginationTrackerDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        transitionToSyncingState()

        let action = BlazeAction.synchronizeCampaigns(siteID: siteID, pageNumber: pageNumber) { [weak self] result in
            switch result {
            case .success(let hasNextPage):
                onCompletion?(.success(hasNextPage))

            case .failure(let error):
                DDLogError("⛔️ Error synchronizing Blaze campaigns: \(error)")
                onCompletion?(.failure(error))
            }
            self?.updateResults()
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
        if campaigns.isEmpty {
            syncState = .syncingFirstPage
        }
    }

    /// Update states after sync is complete.
    func transitionToResultsUpdatedState() {
        shouldShowBottomActivityIndicator = false
        syncState = campaigns.isNotEmpty ? .results : .empty
        if !didShowIntroView {
            shouldShowIntroView = campaigns.isEmpty
            didShowIntroView = true
        }
    }
}

extension UserDefaults {
    /// Checks if the Blaze post campaign creation tip has been displayed for a site.
    ///
    func hasDisplayedTipAfterBlazeCampaignCreation(for siteID: Int64) -> Bool {
        let hasDisplayed = self[.hasDisplayedTipAfterBlazeCampaignCreation] as? [String: Bool]
        let idAsString = "\(siteID)"
        return hasDisplayed?[idAsString] == true
    }

    /// Mark the tip after Blaze campaign creation as displayed for a site.
    ///
    func setBlazePostCreationTipAsDisplayed(for siteID: Int64) {
        let idAsString = "\(siteID)"
        if var hasDisplayed = self[.hasDisplayedTipAfterBlazeCampaignCreation] as? [String: Bool] {
            hasDisplayed[idAsString] = true
            self[.hasDisplayedTipAfterBlazeCampaignCreation] = hasDisplayed
        } else {
            self[.hasDisplayedTipAfterBlazeCampaignCreation] = [idAsString: true]
        }
    }
}
