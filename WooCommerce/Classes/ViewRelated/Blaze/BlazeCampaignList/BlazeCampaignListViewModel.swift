import Foundation
import Yosemite
import Experiments
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// Conformance to support listing in SwiftUI
extension BlazeCampaignListItem: Identifiable {
    public var id: String {
        campaignID
    }
}

/// View model for `BlazeCampaignListView`
final class BlazeCampaignListViewModel: ObservableObject {

    @Published private(set) var campaigns: [BlazeCampaignListItem] = []
    @Published var shouldDisplayPostCampaignCreationTip = false
    @Published var shouldShowIntroView = false
    @Published var selectedCampaignURL: URL?

    private var selectedCampaignID: String?

    /// Tracks whether the intro view has been presented.
    private var didShowIntroView = false

    let siteID: Int64

    var siteURL: String {
        stores.sessionManager.defaultSite?.url ?? ""
    }

    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let userDefaults: UserDefaults
    private let analytics: Analytics
    private let pushNotesManager: PushNotesManager

    /// Keeps track of the current state of the syncing
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    /// Supports infinite scroll.
    private let paginationTracker: PaginationTracker
    private let pageFirstIndex: Int = PaginationTracker.Defaults.pageFirstIndex

    /// Blaze campaign ResultsController.
    private lazy var resultsController: ResultsController<StorageBlazeCampaignListItem> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptorByID = NSSortDescriptor(key: "campaignID",
                                                  ascending: false,
                                                  selector: #selector(NSString.localizedStandardCompare))
        let resultsController = ResultsController<StorageBlazeCampaignListItem>(storageManager: storageManager,
                                                                        matching: predicate,
                                                                        sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    init(siteID: Int64,
         selectedCampaignID: String? = nil,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         userDefaults: UserDefaults = .standard,
         analytics: Analytics = ServiceLocator.analytics,
         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.userDefaults = userDefaults
        self.analytics = analytics
        self.pushNotesManager = pushNotesManager
        self.paginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex)

        configureResultsController()
        configurePaginationTracker()

        if let selectedCampaignID {
            didSelectCampaignDetails(selectedCampaignID)
        }
    }

    /// Called when view first appears.
    func onViewAppear() {
        analytics.track(event: .Blaze.blazeEntryPointDisplayed(source: .campaignList))

        resetNotificationBadgeCount()
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

    func didSelectCampaignDetails(_ campaignID: String) {
        analytics.track(event: .Blaze.blazeCampaignDetailSelected(source: .campaignList))
        selectedCampaignID = campaignID

        let path = String(format: Constants.campaignDetailsURLFormat,
                          campaignID,
                          siteURL.trimHTTPScheme(),
                          BlazeCampaignDetailSource.campaignList.rawValue)
        selectedCampaignURL = URL(string: path)
    }

    func didSelectCreateCampaign(source: BlazeSource) {
        analytics.track(event: .Blaze.blazeEntryPointTapped(source: source))
    }

    func didCreateCampaign() {
        // TODO: make Blaze card appear on the dashboard again
        loadCampaigns()
    }

    func refreshSelectedCampaign() {
        guard let selectedCampaignID else {
            return
        }
        stores.dispatch(BlazeAction.synchronizeCampaign(campaignID: selectedCampaignID, siteID: siteID) { result in
            if case let .failure(error) = result {
                DDLogError("⛔️ Error syncing details for Blaze campaign: \(error)")
            }
        })
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

    func displayIntroViewIfNeeded() {
        if !didShowIntroView {
            shouldShowIntroView = syncState == .empty
            didShowIntroView = true
        }
    }

    /// Clears application icon badge
    ///
    func resetNotificationBadgeCount() {
        let kind: [Note.Kind] = [.blazeApprovedNote, .blazeRejectedNote, .blazeCancelledNote, .blazePerformedNote]
        kind.forEach { kind in
            pushNotesManager.resetBadgeCount(type: kind)
        }
    }
}

extension BlazeCampaignListViewModel: PaginationTrackerDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        transitionToSyncingState()

        let skip = {
            guard pageNumber > 1 else {
                return 0
            }
            return pageSize * (pageNumber - 1)
        }()
        let action = BlazeAction.synchronizeCampaignsList(siteID: siteID,
                                                          skip: skip,
                                                          limit: pageSize) { [weak self] result in
            switch result {
            case .success(let hasNextPage):
                onCompletion?(.success(hasNextPage))

            case .failure(let error):
                DDLogError("⛔️ Error synchronizing Blaze campaigns: \(error)")
                onCompletion?(.failure(error))
            }

            self?.updateResults()
            self?.displayIntroViewIfNeeded()
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
    }
}

private extension BlazeCampaignListViewModel {
    enum Constants {
        static let campaignDetailsURLFormat = "https://wordpress.com/advertising/campaigns/%@/%@?source=%@"
    }
}
