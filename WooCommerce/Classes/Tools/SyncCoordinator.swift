import Foundation
import Yosemite


/// SyncingCoordinatorDelegate: Delegate that's expected to provide Sync'ing Services per Page.
///
protocol SyncingCoordinatorDelegate: class {

    /// The receiver is expected to synchronize the pageNumber. On completion, it should indicate if the sync was
    /// successful or not.
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: ((Bool) -> Void)?)
}


/// SyncingCoordinator: Encapsulates all of the "Last Refreshed / Should Refresh" Paging Logic.
///
/// Note:
/// Sync'ing of first page isn't really handled. Reason is: the first page of each collection must always be fresh,
/// and the Sync OP is (usually) explicitly made in `viewWillAppear`. This may change in a future update, though!
///
class SyncingCoordinator {

    /// Default Settings
    ///
    enum Defaults {
        static let pageFirstIndex = Store.Default.firstPageNumber
        static let pageSize = 25
        static let pageTTLInSeconds = TimeInterval(3 * 60)
    }

    /// Maps Page Numbers > Refresh Dates
    ///
    private var refreshDatePerPage = [Int: Date]()

    /// Indexes of the pages being currently Sync'ed
    ///
    private var pagesBeingSynced = IndexSet()

    /// First Page Index
    ///
    let pageFirstIndex: Int

    /// Number of elements retrieved per request.
    ///
    let pageSize: Int

    /// Time (In Seconds) that must elapse before a Page is considered "expired".
    ///
    let pageTTLInSeconds: TimeInterval

    /// Returns the Highest Page being currenty synced (if any)
    ///
    var highestPageBeingSynced: Int? {
        return pagesBeingSynced.max()
    }

    /// Sync'ing Delegate
    ///
    weak var delegate: SyncingCoordinatorDelegate?

    /// Designated Initializer
    ///
    init(pageFirstIndex: Int = Defaults.pageFirstIndex,
         pageSize: Int = Defaults.pageSize,
         pageTTLInSeconds: TimeInterval = Defaults.pageTTLInSeconds) {

        self.pageFirstIndex = pageFirstIndex
        self.pageSize = pageSize
        self.pageTTLInSeconds = pageTTLInSeconds
    }


    /// Should be called whenever a given Entity becomes visible. This method will:
    ///
    ///     1.  Proceed only if a given Element is the last one in it's page
    ///     2.  Verify if the (NEXT) page isn't being sync'ed (OR) if its cache has expired
    ///     3.  Proceed sync'ing the next page, if possible / needed
    ///
    func ensureNextPageIsSynchronized(lastVisibleIndex: Int) {
        guard isLastElementInPage(elementIndex: lastVisibleIndex) else {
            return
        }

        let nextPage = pageNumber(for: lastVisibleIndex) + 1
        guard !isPageBeingSynced(pageNumber: nextPage), isCacheInvalid(pageNumber: nextPage) else {
            return
        }

        synchronize(pageNumber: nextPage)
    }

    /// Resets Internal State + (RE)synchronizes the first page in the collection.
    ///
    func resynchronize(reason: String? = nil, onCompletion: (() -> Void)? = nil) {
        resetInternalState()
        synchronizeFirstPage(onCompletion: onCompletion)
    }

    /// Synchronizes the First Page in the collection.
    ///
    func synchronizeFirstPage(reason: String? = nil, onCompletion: (() -> Void)? = nil) {
        synchronize(pageNumber: pageFirstIndex, reason: reason, onCompletion: onCompletion)
    }
}


// MARK: - Sync'ing Core
//
private extension SyncingCoordinator {

    /// Synchronizes a given Page Number
    ///
    func synchronize(pageNumber: Int, reason: String? = nil, onCompletion: (() -> Void)? = nil) {
        guard let delegate = delegate else {
            fatalError()
        }

        markAsBeingSynced(pageNumber: pageNumber)

        delegate.sync(pageNumber: pageNumber, pageSize: pageSize, reason: reason) { success in
            if success {
                self.markAsUpdated(pageNumber: pageNumber)
            }

            self.unmarkAsBeingSynced(pageNumber: pageNumber)
            onCompletion?()
        }
    }
}


// MARK: - Analyzer Methods: For unit testing purposes, marking them as `Internal`
//
extension SyncingCoordinator {

    /// Resets all of the internal structures
    ///
    func resetInternalState() {
        pagesBeingSynced.removeAll()
        refreshDatePerPage.removeAll()
    }

    /// Maps an ObjectIndex to a PageNumber: [1, ...)
    ///
    func pageNumber(for objectIndex: Int) -> Int {
        return objectIndex / pageSize + 1
    }

    /// Indicates if the Cache for a given PageNumber is Invalid: Never Sync'ed (OR) TTL Expired
    ///
    func isCacheInvalid(pageNumber: Int) -> Bool {
        guard let elapsedTime = refreshDatePerPage[pageNumber]?.timeIntervalSinceNow else {
            return true
        }

        return abs(elapsedTime) > pageTTLInSeconds
    }

    /// Indicates if a given Element is the last one in the page. Note that `elementIndex` is expected to be in the [0, N) range.
    ///
    func isLastElementInPage(elementIndex: Int) -> Bool {
        return (elementIndex % pageSize) == (pageSize - 1)
    }

    /// Indicates if a given PageNumber is currently being synced
    ///
    func isPageBeingSynced(pageNumber: Int) -> Bool {
        return pagesBeingSynced.contains(pageNumber)
    }
}


// MARK: - Private Methods
//
private extension SyncingCoordinator {

    /// Marks the specified PageNumber as just Updated
    ///
    func markAsUpdated(pageNumber: Int) {
        refreshDatePerPage[pageNumber] = Date()
    }

    /// Marks the specified PageNumber as "In Sync"
    ///
    func markAsBeingSynced(pageNumber: Int) {
        pagesBeingSynced.insert(pageNumber)
    }

    /// Removes the specified PageNumber from the "In Sync" collection
    ///
    func unmarkAsBeingSynced(pageNumber: Int) {
        pagesBeingSynced.remove(pageNumber)
    }
}
