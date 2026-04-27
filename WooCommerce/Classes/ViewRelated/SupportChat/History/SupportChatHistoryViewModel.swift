import Foundation
import Observation
import Yosemite
import protocol WooFoundation.Analytics

/// View model backing the chat history list. Loads persisted chat bookmarks
/// for the current site and supports swipe-to-delete.
///
@MainActor
@Observable
final class SupportChatHistoryViewModel {
    private(set) var summaries: [SupportChatSummary] = []

    private let stores: StoresManager
    private let analytics: Analytics
    private let siteID: Int64
    private var openedTracked = false

    init(stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         siteID: Int64) {
        self.stores = stores
        self.analytics = analytics
        self.siteID = siteID
    }

    func load() {
        let action = SupportChatAction.loadChatHistory(siteID: siteID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let summaries):
                self.summaries = summaries
                if !self.openedTracked {
                    self.openedTracked = true
                    self.analytics.track(event: .SupportChat.historyOpened(chatCount: summaries.count))
                }
            case .failure(let error):
                DDLogError("⛔️ Failed to load support chat history: \(error)")
            }
        }
        stores.dispatch(action)
    }

    func delete(at indexSet: IndexSet) {
        let chatIDsToDelete = indexSet.map { summaries[$0].chatID }

        // Remove from the local array first for snappy UI; the dispatched action is fire-and-forget.
        summaries.remove(atOffsets: indexSet)

        for chatID in chatIDsToDelete {
            analytics.track(event: .SupportChat.historyDeleted(chatID: chatID))
            let action = SupportChatAction.deleteChat(chatID: chatID, onCompletion: { _ in })
            stores.dispatch(action)
        }
    }
}
