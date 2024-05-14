import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `InboxDashboardCard`.
///
final class InboxDashboardCardViewModel: ObservableObject {
    // Set externally to trigger callback upon hiding the Inbox card.
    var onDismiss: (() -> Void)?

    @Published private(set) var syncState: InboxViewModel.SyncState = .empty

    /// View models for inbox note rows.
    @Published private(set) var noteRowViewModels: [InboxNoteRowViewModel] = []

    private let siteID: Int64
    private let analytics: Analytics

    let contentViewModel: InboxViewModel

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.analytics = analytics
        self.contentViewModel = InboxViewModel(siteID: siteID, pageSize: 3, stores: stores, storageManager: storage)

        forwardStatesFromContentViewModel()
    }

    @MainActor
    func reloadData() async {
        await withCheckedContinuation { continuation in
            contentViewModel.onRefreshAction {
                continuation.resume()
            }
        }
    }

    func dismissInbox() {
        // TODO: add tracking
        onDismiss?()
    }
}

// MARK: - Private helpers
private extension InboxDashboardCardViewModel {
    func forwardStatesFromContentViewModel() {
        contentViewModel.$noteRowViewModels
            .assign(to: &$noteRowViewModels)

        contentViewModel.$syncState
            .assign(to: &$syncState)
    }
}
