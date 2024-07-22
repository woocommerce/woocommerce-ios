import Foundation
import Yosemite
import class Networking.InboxNotesRemote
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `InboxDashboardCard`.
///
@MainActor
final class InboxDashboardCardViewModel: ObservableObject {
    // Set externally to trigger callback upon hiding the Inbox card.
    var onDismiss: (() -> Void)?

    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?

    /// View models for inbox note rows.
    @Published private(set) var noteRowViewModels: [InboxNoteRowViewModel] = []

    let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics

    /// Inbox notes ResultsController.
    private lazy var resultsController: ResultsController<StorageInboxNote> = {
        let predicate = NSPredicate(format: "siteID == %lld AND isRemoved == NO", siteID)
        let sortDescriptorByDateCreated = NSSortDescriptor(keyPath: \StorageInboxNote.dateCreated, ascending: false)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageInboxNote.id, ascending: true)
        let resultsController = ResultsController<StorageInboxNote>(storageManager: storageManager,
                                                                    matching: predicate,
                                                                    fetchLimit: Constants.numberOfItems,
                                                                    sortedBy: [sortDescriptorByDateCreated, sortDescriptorByID])
        return resultsController
    }()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.analytics = analytics
        self.stores = stores
        self.storageManager = storageManager

        configureResultsController()
    }

    @MainActor
    func reloadData() async {
        analytics.track(event: .DynamicDashboard.cardLoadingStarted(type: .inbox))
        syncingData = true
        syncingError = nil
        do {
            // Ignoring the result from remote as we're using storage as the single source of truth
            _ = try await loadInboxMessages()
            analytics.track(event: .DynamicDashboard.cardLoadingCompleted(type: .inbox))
        } catch {
            syncingError = error
            analytics.track(event: .DynamicDashboard.cardLoadingFailed(type: .inbox, error: error))
        }
        syncingData = false
    }

    func dismissInbox() {
        analytics.track(event: .DynamicDashboard.hideCardTapped(type: .inbox))
        onDismiss?()
    }
}

// MARK: - Private helpers
private extension InboxDashboardCardViewModel {
    @MainActor
    func loadInboxMessages() async throws -> [InboxNote] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(InboxNotesAction.loadAllInboxNotes(siteID: siteID,
                                                               pageNumber: 1,
                                                               pageSize: Constants.numberOfItems,
                                                               orderBy: .date,
                                                               type: InboxViewModel.noteTypes,
                                                               status: InboxViewModel.noteStatuses) { result in
                continuation.resume(with: result)
            })
        }
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

    /// Updates row view models.
    func updateResults() {
        noteRowViewModels = resultsController.fetchedObjects
            .prefix(Constants.numberOfItems)
            .map { InboxNoteRowViewModel(note: $0) }
    }
}

private extension InboxDashboardCardViewModel {
    enum Constants {
        static let numberOfItems = 3
    }
}
