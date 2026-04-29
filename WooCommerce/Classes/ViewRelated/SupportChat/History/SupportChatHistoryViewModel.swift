import Foundation
import Observation
import Yosemite

/// View model backing the chat history list. Loads persisted chat bookmarks
/// for the current site and supports swipe-to-delete.
///
@MainActor
@Observable
final class SupportChatHistoryViewModel {
    private(set) var summaries: [SupportChatSummary] = []

    private let stores: StoresManager
    private let siteID: Int64

    init(stores: StoresManager = ServiceLocator.stores, siteID: Int64) {
        self.stores = stores
        self.siteID = siteID
    }

    func load() {
        let action = SupportChatAction.loadChatHistory(siteID: siteID) { [weak self] summaries in
            self?.summaries = summaries
        }
        stores.dispatch(action)
    }

    func delete(at indexSet: IndexSet) {
        let chatIDsToDelete = indexSet.map { summaries[$0].chatID }

        // Remove from the local array first for snappy UI; the dispatched action is fire-and-forget.
        summaries.remove(atOffsets: indexSet)

        for chatID in chatIDsToDelete {
            let action = SupportChatAction.deleteChat(chatID: chatID, onCompletion: {})
            stores.dispatch(action)
        }
    }
}
