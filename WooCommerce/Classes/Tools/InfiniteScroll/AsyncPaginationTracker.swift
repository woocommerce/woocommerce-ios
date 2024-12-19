import Yosemite

/// Keeps track of the pagination for API syncing to support infinite scroll.
final class AsyncPaginationTracker {
    typealias SyncFunction = (_ pageNumber: Int) async throws -> Bool

    /// State of loading the next page in `ensureNextPageIsSynced`.
    enum NextPageSyncState {
        case syncing
        case synced
        case noNextPage
    }

    /// Default pagination settings.
    enum Defaults {
        static let pageFirstIndex = Store.Default.firstPageNumber
    }

    /// The index of the first page in the API. So far, both Woo and WP.com API have the first page index at 1.
    private let pageFirstIndex: Int

    /// Indexes of the pages that have been successfully synced.
    private var pagesSynced = IndexSet()

    /// Indexes of the pages being currently synced.
    private var pagesBeingSynced = IndexSet()

    /// Whether there might be more pages to fetch from the API, set by the sync completion.
    private var hasNextPage: Bool = true

    /// Returns the highest page number that has been successfully synced, if any.
    private var highestPageSynced: Int? {
        pagesSynced.max()
    }

    /// Returns the highest page number that is currently being synced, if any.
    private var highestPageBeingSynced: Int? {
        pagesBeingSynced.max()
    }

    /// Designated Initializer
    init(pageFirstIndex: Int = Defaults.pageFirstIndex) {
        self.pageFirstIndex = pageFirstIndex
    }

    /// Should be called whenever a scroll position is approaching the end of the list for infinite scroll support.
    /// This method will:
    ///     1.  Proceed only if a given element is the last one in its page
    ///     2.  Verify if the next page isn't currently being synced
    ///     3.  Proceed syncing the next page, if possible / needed
    func ensureNextPageIsSynced(syncFunction: @escaping SyncFunction) async throws -> NextPageSyncState {
        guard hasNextPage else {
            return .noNextPage
        }

        let nextPage = (highestPageSynced ?? pageFirstIndex - 1) + 1
        guard !isPageBeingSynced(pageNumber: nextPage) else {
            return .syncing
        }
        try await sync(pageNumber: nextPage, syncFunction: syncFunction)
        return .synced
    }

    /// Resets internal states and resyncs the first page of results.
    ///
    func resync(syncFunction: @escaping SyncFunction) async throws {
        resetInternalState()
        try await syncFirstPage( syncFunction: syncFunction)
    }

    /// Syncs the first page of results.
    ///
    func syncFirstPage(syncFunction: @escaping SyncFunction) async throws {
        try await sync(pageNumber: pageFirstIndex, syncFunction: syncFunction)
    }
}

// MARK: - Syncing Core
//
private extension AsyncPaginationTracker {
    /// Syncs a given page number.
    func sync(pageNumber: Int, syncFunction: @escaping SyncFunction) async throws {
        markAsBeingSynced(pageNumber: pageNumber)

        do {
            let hasNextPage = try await syncFunction(pageNumber)
            self.hasNextPage = hasNextPage
            markAsSynced(pageNumber: pageNumber)
        } catch {
            throw error
        }

        unmarkAsBeingSynced(pageNumber: pageNumber)
    }
}

// MARK: - Private Methods
//
private extension AsyncPaginationTracker {
    /// Resets all of the internal structures.
    func resetInternalState() {
        pagesBeingSynced.removeAll()
        pagesSynced.removeAll()
        hasNextPage = true
    }

    /// Indicates if a given page number is currently being synced.
    func isPageBeingSynced(pageNumber: Int) -> Bool {
        return pagesBeingSynced.contains(pageNumber)
    }

    /// Marks the specified page number as synced with the current date.
    func markAsSynced(pageNumber: Int) {
        pagesSynced.insert(pageNumber)
    }

    /// Marks the specified page number as being synced.
    func markAsBeingSynced(pageNumber: Int) {
        pagesBeingSynced.insert(pageNumber)
    }

    /// Removes the specified page number from the "In Sync" collection.
    func unmarkAsBeingSynced(pageNumber: Int) {
        pagesBeingSynced.remove(pageNumber)
    }
}
