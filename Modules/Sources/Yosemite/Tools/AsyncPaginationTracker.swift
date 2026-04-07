import Foundation

/// Async/await version of `PaginationTracker`, consider renaming `PaginationTracker` as deprecated and this class to `PaginationTracker`.
/// Keeps track of the pagination for API syncing to support infinite scroll and pull-to-refresh.
public final class AsyncPaginationTracker {
    public typealias SyncFunction = (_ pageNumber: Int) async throws -> Bool

    /// State of loading the next page in `ensureNextPageIsSynced`.
    public enum NextPageSyncState {
        case syncing
        case synced
        case noNextPage
    }

    /// Default pagination settings.
    public enum Defaults {
        public static let pageFirstIndex = Store.Default.firstPageNumber
    }

    /// The index of the first page in the API. So far, both Woo and WP.com API have the first page index at 1.
    private let pageFirstIndex: Int

    private let lock = NSLock()

    /// Indexes of the pages that have been successfully synced.
    private var pagesSynced = IndexSet()

    /// Indexes of the pages being currently synced.
    private var pagesBeingSynced = IndexSet()

    /// Whether there might be more pages to fetch from the API, set by the sync function.
    private(set) public var hasNextPage: Bool = true

    /// Returns the highest page number that has been successfully synced, if any.
    private var highestPageSynced: Int? {
        lock.withLock { pagesSynced.max() }
    }

    /// Designated Initializer
    public init(pageFirstIndex: Int = Defaults.pageFirstIndex) {
        self.pageFirstIndex = pageFirstIndex
    }

    /// Should be called whenever a scroll position is approaching the end of the list for infinite scroll support.
    /// This method will:
    ///     1.  Proceed only if there is next page to sync.
    ///     2.  Verify if the next page isn't currently being synced.
    ///     3.  Proceed syncing the next page.
    public func ensureNextPageIsSynced(syncFunction: @escaping SyncFunction) async throws -> NextPageSyncState {
        guard lock.withLock({ hasNextPage }) else {
            return .noNextPage
        }

        let nextPage = (lock.withLock({ pagesSynced.max() }) ?? pageFirstIndex - 1) + 1
        guard !isPageBeingSynced(pageNumber: nextPage) else {
            return .syncing
        }
        do {
            try await sync(pageNumber: nextPage, syncFunction: syncFunction)
            return .synced
        } catch {
            throw error
        }
    }

    /// Resets internal states and resyncs the first page of results.
    ///
    public func resync(syncFunction: @escaping SyncFunction) async throws {
        resetInternalState()
        try await syncFirstPage(syncFunction: syncFunction)
    }

    /// Syncs the first page of results.
    ///
    public func syncFirstPage(syncFunction: @escaping SyncFunction) async throws {
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
            defer {
                unmarkAsBeingSynced(pageNumber: pageNumber)
            }
            let hasNextPage = try await syncFunction(pageNumber)
            lock.withLock { self.hasNextPage = hasNextPage }
            markAsSynced(pageNumber: pageNumber)
        } catch {
            throw error
        }
    }
}

// MARK: - Private Methods
//
private extension AsyncPaginationTracker {
    /// Resets all of the internal structures.
    func resetInternalState() {
        lock.withLock {
            pagesBeingSynced.removeAll()
            pagesSynced.removeAll()
            hasNextPage = true
        }
    }

    /// Indicates if a given page number is currently being synced.
    func isPageBeingSynced(pageNumber: Int) -> Bool {
        lock.withLock { pagesBeingSynced.contains(pageNumber) }
    }

    /// Marks the specified page number as synced with the current date.
    func markAsSynced(pageNumber: Int) {
        lock.withLock { pagesSynced.insert(pageNumber) }
    }

    /// Marks the specified page number as being synced.
    func markAsBeingSynced(pageNumber: Int) {
        lock.withLock { pagesBeingSynced.insert(pageNumber) }
    }

    /// Removes the specified page number from the "In Sync" collection.
    func unmarkAsBeingSynced(pageNumber: Int) {
        lock.withLock { pagesBeingSynced.remove(pageNumber) }
    }
}
