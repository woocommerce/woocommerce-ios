import class Networking.InboxNotesRemote
import protocol Storage.StorageManagerType
import Yosemite
import Combine
import Foundation

/// View model for `Inbox` that handles actions that change the view state and provides view data.
final class InboxViewModel: ObservableObject {
    /// Trigger to perform any one time setups.
    let onLoadTrigger: PassthroughSubject<Void, Never> = PassthroughSubject()

    /// View models for inbox note rows.
    @Published private(set) var noteRowViewModels: [InboxNoteRowViewModel] = []

    /// View models for placeholder rows.
    static let placeholderRowViewModels: [InboxNoteRowViewModel] = [Int64](0..<3).map {
        // The content does not matter because the text in placeholder rows is redacted.
        InboxNoteRowViewModel(id: $0,
                              date: "   ",
                              title: "            ",
                              attributedContent: .init(),
                              actions: [.init(id: 0, title: "Placeholder", url: nil)],
                              siteID: 123,
                              isPlaceholder: true,
                              isRead: true,
                              isSurvey: false,
                              isActioned: false)
    }

    // MARK: Sync

    /// Current sync status; used to determine the view state.
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    private let pageSize: Int
    static let noteTypes: [InboxNotesRemote.NoteType]? = [.info, .marketing, .survey, .warning]
    static let noteStatuses: [InboxNotesRemote.Status]? = [.unactioned, .actioned]

    private var highestSyncedPageNumber: Int = 0

    /// Supports infinite scroll.
    private let paginationTracker: PaginationTracker

    private let pageFirstIndex: Int = PaginationTracker.Defaults.pageFirstIndex

    /// Storage to fetch inbox notes.
    private let storageManager: StorageManagerType

    /// Inbox notes ResultsController.
    private lazy var resultsController: ResultsController<StorageInboxNote> = {
        let predicate = NSPredicate(format: "siteID == %lld AND isRemoved == NO", siteID)
        let sortDescriptorByDateCreated = NSSortDescriptor(keyPath: \StorageInboxNote.dateCreated, ascending: false)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageInboxNote.id, ascending: true)
        let resultsController = ResultsController<StorageInboxNote>(storageManager: storageManager,
                                                                    matching: predicate,
                                                                    sortedBy: [sortDescriptorByDateCreated, sortDescriptorByID])
        return resultsController
    }()

    /// Stores to sync inbox notes and handle note actions.
    private let stores: StoresManager

    private let siteID: Int64
    private var subscriptions = Set<AnyCancellable>()

    init(siteID: Int64,
         syncState: SyncState = .empty,
         pageSize: Int = PaginationTracker.Defaults.pageSize,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.syncState = syncState
        self.pageSize = pageSize
        self.paginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex, pageSize: pageSize)

        configureResultsController()
        configurePaginationTracker()
        configureFirstPageLoad()
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

// MARK: - Sync Methods

private extension InboxViewModel {
    /// Syncs the first page of inbox notes from remote.
    func syncFirstPage() {
        paginationTracker.syncFirstPage()
    }
}

extension InboxViewModel: PaginationTrackerDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        transitionToSyncingState()

        let action = InboxNotesAction.loadAllInboxNotes(siteID: siteID,
                                                        pageNumber: pageNumber,
                                                        pageSize: pageSize,
                                                        type: Self.noteTypes,
                                                        status: Self.noteStatuses) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let notes):
                ServiceLocator.analytics.track(.inboxNotesLoaded,
                                               withProperties: ["is_loading_more": pageNumber != self.pageFirstIndex])
                let hasNextPage = notes.count == pageSize
                onCompletion?(.success(hasNextPage))

                self.highestSyncedPageNumber = pageNumber

                // If the store has no inbox notes and thus there are no inbox notes for the first page, `ResultsController`'s
                // callbacks from storage layer changes are not triggered and we have to manually update to `SyncState.empty` in this case.
                if pageNumber == self.pageFirstIndex && notes.isEmpty {
                    self.syncState = .empty
                }
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing inbox notes: \(error)")
                ServiceLocator.analytics.track(.inboxNotesLoadedFailed, withError: error)
                onCompletion?(.failure(error))
            }
        }
        stores.dispatch(action)
    }

    func dismissAllInboxNotes() {
        ServiceLocator.analytics.track(.inboxNoteAction,
                                       withProperties: ["action": "dismiss_all"])

        // Since the dismiss all API endpoint only deletes notes that match the given parameters, we want to match the parameters with the load request
        // and specify the page size to include all the synced notes based on the last sync request.
        let pageSizeForAllSyncedNotes = highestSyncedPageNumber * pageSize
        let action = InboxNotesAction.dismissAllInboxNotes(siteID: siteID,
                                                           pageSize: pageSizeForAllSyncedNotes,
                                                           type: Self.noteTypes,
                                                           status: Self.noteStatuses) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                DDLogError("⛔️ Error on dismissing all inbox notes: \(error)")
            }
        }
        stores.dispatch(action)
    }
}

// MARK: - Configuration

private extension InboxViewModel {
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
        noteRowViewModels = resultsController.fetchedObjects.map { .init(note: $0) }
        transitionToResultsUpdatedState()
    }
}

// MARK: - State Machine

extension InboxViewModel {
    /// Represents possible states for syncing inbox notes.
    enum SyncState: Equatable {
        case syncingFirstPage
        case results
        case empty
    }

    /// Update states for sync from remote.
    func transitionToSyncingState() {
        shouldShowBottomActivityIndicator = true
        if noteRowViewModels.isEmpty {
            syncState = .syncingFirstPage
        }
    }

    /// Update states after sync is complete.
    func transitionToResultsUpdatedState() {
        shouldShowBottomActivityIndicator = false
        syncState = noteRowViewModels.isNotEmpty ? .results: .empty
    }
}
