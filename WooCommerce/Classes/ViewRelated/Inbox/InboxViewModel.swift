import Yosemite
import Combine
import Foundation

/// View model for `Inbox` that handles actions that change the view state and provides view data.
final class InboxViewModel: ObservableObject {
    /// Trigger to perform any one time setups.
    let onLoadTrigger: PassthroughSubject<Void, Never> = PassthroughSubject()

    /// All inbox notes.
    @Published private var notes: [InboxNote] = []

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
                              actions: [.init(id: 0, title: "Placeholder", url: nil)])
    }

    // MARK: Sync

    /// Current sync status; used to determine the view state.
    @Published private(set) var syncState: SyncState = .empty

    /// Tracks if the infinite scroll indicator should be displayed.
    @Published private(set) var shouldShowBottomActivityIndicator = false

    /// Supports infinite scroll.
    private let paginationTracker: PaginationTracker

    /// Stores to sync inbox notes and handle note actions.
    private let stores: StoresManager

    private let siteID: Int64
    private var subscriptions = Set<AnyCancellable>()

    init(siteID: Int64,
         syncState: SyncState = .empty,
         pageSize: Int = SyncingCoordinator.Defaults.pageSize,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
        self.syncState = syncState
        self.paginationTracker = PaginationTracker(pageSize: pageSize)

        $notes.map { $0.map { InboxNoteRowViewModel(note: $0) } }.assign(to: &$noteRowViewModels)

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
                                                        type: nil,
                                                        status: nil) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let notes):
                self.notes.append(contentsOf: notes)
                let hasNextPage = notes.count == pageSize
                onCompletion?(.success(hasNextPage))
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing inbox notes: \(error)")
                onCompletion?(.failure(error))
            }
            self.transitionToResultsUpdatedState()
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
        if notes.isEmpty {
            syncState = .syncingFirstPage
        }
    }

    /// Update states after sync is complete.
    func transitionToResultsUpdatedState() {
        shouldShowBottomActivityIndicator = false
        syncState = notes.isNotEmpty ? .results: .empty
    }
}
