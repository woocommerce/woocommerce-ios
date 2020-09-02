import Yosemite

/// Delegate of `PaginationTracker` that implements syncing per page number and size.
protocol PaginationTrackerDelegate: class {
    typealias SyncCompletion = (Result<Bool, Error>) -> Void

    /// Syncs a page by the number and size, and returns an error or whether there might be the next page on completion.
    ///
    /// - Parameter reason: A value passed from `resync` or `syncFirstPage`. This can
    ///                     be used to decide how to perform the sync.
    /// - Parameter onCompletion: called on sync completion that returns either an error or a boolean that indicates
    ///                           whether there might be the next page to sync.
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?)
}

/// Keeps track of the pagination for API syncing to support infinite scroll.
final class PaginationTracker {
    /// Default Settings
    private enum Defaults {
        static let pageFirstIndex = Store.Default.firstPageNumber
        static let pageSize = 25
    }

    /// First Page Index
    private let pageFirstIndex: Int

    /// Number of elements retrieved per request.
    private let pageSize: Int

    /// Syncing delegate
    weak var delegate: PaginationTrackerDelegate?

    /// Maps from a page number to the last synced date.
    private var syncedDatesByPage = [Int: Date]()

    /// Indexes of the pages being currently synced
    private var pagesBeingSynced = IndexSet()

    /// Whether there might be more pages to fetch from the API, set by the sync completion.
    private var hasNextPage: Bool = true

    /// Returns the highest page number that is currently being synced, if any.
    private var highestPageBeingSynced: Int? {
        pagesBeingSynced.max()
    }

    /// Returns the highest page number that has been successfully synced.
    private var highestPageSynced: Int? {
        syncedDatesByPage.keys.max()
    }

    /// Designated Initializer
    init(pageFirstIndex: Int = Defaults.pageFirstIndex,
         pageSize: Int = Defaults.pageSize) {
        self.pageFirstIndex = pageFirstIndex
        self.pageSize = pageSize
    }

    /// Should be called whenever a scroll position is approaching the end of the list for infinite scroll support.
    /// This method will:
    ///     1.  Proceed only if a given element is the last one in it's page
    ///     2.  Verify if the nextpage isn't currently being synced
    ///     3.  Proceed syncing the next page, if possible / needed
    func ensureNextPageIsSynced() {
        guard hasNextPage else {
            return
        }

        let nextPage = (highestPageSynced ?? pageFirstIndex - 1) + 1
        guard !isPageBeingSynced(pageNumber: nextPage) else {
            return
        }
        sync(pageNumber: nextPage)
    }

    /// Resets internal states and resyncs the first page of results.
    ///
    /// - Parameter reason: A value passed back to the `delegate`. This can be used to provide
    ///                     additional information for the `delegate` and is not used internally
    ///                     by `PaginationTracker`.
    func resync(reason: String? = nil, onCompletion: (() -> Void)? = nil) {
        resetInternalState()
        syncFirstPage(reason: reason, onCompletion: onCompletion)
    }

    /// Syncs the first page of results.
    ///
    /// - Parameter reason: A value passed back to the `delegate`. This can be used to provide
    ///                     additional information for the `delegate` and is not used internally
    ///                     by `PaginationTracker`.
    func syncFirstPage(reason: String? = nil, onCompletion: (() -> Void)? = nil) {
        sync(pageNumber: pageFirstIndex, reason: reason, onCompletion: onCompletion)
    }
}

// MARK: - Syncing Core
//
private extension PaginationTracker {
    /// Syncs a given page number.
    func sync(pageNumber: Int, reason: String? = nil, onCompletion: (() -> Void)? = nil) {
        guard let delegate = delegate else {
            fatalError()
        }

        markAsBeingSynced(pageNumber: pageNumber)

        delegate.sync(pageNumber: pageNumber, pageSize: pageSize, reason: reason) { [weak self] result in
            guard let self = self else {
                return
            }

            if case let .success(hasNextPage) = result {
                self.hasNextPage = hasNextPage
                self.markAsSynced(pageNumber: pageNumber)
            }

            self.unmarkAsBeingSynced(pageNumber: pageNumber)
            onCompletion?()
        }
    }
}

// MARK: - Private Methods
//
private extension PaginationTracker {
    /// Resets all of the internal structures.
    func resetInternalState() {
        pagesBeingSynced.removeAll()
        syncedDatesByPage.removeAll()
        hasNextPage = true
    }

    /// Indicates if a given page number is currently being synced.
    func isPageBeingSynced(pageNumber: Int) -> Bool {
        return pagesBeingSynced.contains(pageNumber)
    }

    /// Marks the specified page number as synced with the current date.
    func markAsSynced(pageNumber: Int) {
        syncedDatesByPage[pageNumber] = Date()
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
