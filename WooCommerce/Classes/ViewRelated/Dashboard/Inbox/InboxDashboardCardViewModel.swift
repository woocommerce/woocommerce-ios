import Foundation
import Yosemite
import class Networking.InboxNotesRemote
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `InboxDashboardCard`.
///
final class InboxDashboardCardViewModel: ObservableObject {
    // Set externally to trigger callback upon hiding the Inbox card.
    var onDismiss: (() -> Void)?

    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?

    /// View models for inbox note rows.
    @Published private(set) var noteRowViewModels: [InboxNoteRowViewModel] = []

    private let siteID: Int64
    private let stores: StoresManager
    private let storage: StorageManagerType
    private let analytics: Analytics

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.analytics = analytics
        self.stores = stores
        self.storage = storage
    }

    @MainActor
    func reloadData() async {
        syncingData = true
        syncingError = nil
        do {
            let notes = try await loadInboxMessages()
            noteRowViewModels = notes.map { InboxNoteRowViewModel(note: $0) }
        } catch {
            syncingError = error
        }
        syncingData = false
    }

    func dismissInbox() {
        // TODO: add tracking
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
                                                               pageSize: 3,
                                                               type: InboxViewModel.noteTypes,
                                                               status: InboxViewModel.noteStatuses) { result in
                continuation.resume(with: result)
            })
        }
    }
}
