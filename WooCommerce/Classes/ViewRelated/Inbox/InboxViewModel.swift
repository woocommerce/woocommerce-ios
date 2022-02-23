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
    let placeholderRowViewModels: [InboxNoteRowViewModel] = [Int64](0..<3).map {
        // The content does not matter because the text in placeholder rows is redacted.
        InboxNoteRowViewModel(id: $0,
                              date: "   ",
                              typeIcon: .init(uiImage: .infoImage),
                              title: "            ",
                              attributedContent: .init(string: "\n\n\n"),
                              actions: [.init(id: 0, title: "Placeholder", url: nil)],
                              siteID: 123)
    }

    // MARK: Sync

    /// Current sync status; used to determine the view state.
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

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
        self.paginationTracker = PaginationTracker(pageFirstIndex: pageFirstIndex, pageSize: pageSize)

        configureResultsController()
        configurePaginationTracker()
        configureFirstPageLoad()
    }

    /// Called when the next page should be loaded.
    func onLoadNextPageAction() {
        paginationTracker.ensureNextPageIsSynced()
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
                                                        orderBy: .date,
                                                        type: [.info, .marketing, .survey, .warning],
                                                        status: [.unactioned, .actioned]) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let notes):
                let hasNextPage = notes.count == pageSize
                onCompletion?(.success(hasNextPage))
                // If the store has no inbox notes and thus there are no inbox notes for the first page, `ResultsController`'s
                // callbacks from storage layer changes are not triggered and we have to manually update to `SyncState.empty` in this case.
                if pageNumber == self.pageFirstIndex && notes.isEmpty {
                    self.syncState = .empty
                }
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing inbox notes: \(error)")
                onCompletion?(.failure(error))
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
