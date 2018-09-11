import Foundation



///
///
protocol SyncingCoordinatorDelegate: class {
    func sync(page: Int, onCompletion: (() -> Void)?)
}


///
///
class SyncingCoordinator {

    ///
    ///
    private var refreshDatePerPage = [Int: Date]()

    ///
    ///
    private var pagesBeingSynced = IndexSet()

    ///
    ///
    let pageSize: Int

    ///
    ///
    let pageTTLInSeconds: TimeInterval

    ///
    ///
    weak var delegate: SyncingCoordinatorDelegate?

    ///
    ///
    init(pageSize: Int, pageTTLInSeconds: TimeInterval) {
        self.pageSize = pageSize
        self.pageTTLInSeconds = pageTTLInSeconds
    }


    ///
    ///
    func ensureResultsAreSynchronized(lastVisibleIndex: Int) {
        guard isLastElementInPage(elementIndex: lastVisibleIndex) else {
            return
        }

        let nextPage = pageNumber(for: lastVisibleIndex) + 1
        guard isPageBeingSynced(page: nextPage) == false, isCacheInvalid(page: nextPage) else {
            return
        }

        NSLog("### Syncing Page: \(nextPage)")

        markAsBeingSynced(page: nextPage)

        delegate?.sync(page: nextPage) {
            // TODO: Handle Errors
            self.markAsUpdated(page: nextPage)
            self.unmarkAsBeingSynced(page: nextPage)
        }
    }
}


///
///
private extension SyncingCoordinator {

    func pageNumber(for objectIndex: Int) -> Int {
        return objectIndex / pageSize
    }

    func isCacheInvalid(page: Int) -> Bool {
        guard let elapsedTime = refreshDatePerPage[page]?.timeIntervalSinceNow else {
            return false
        }

        return elapsedTime > pageTTLInSeconds
    }

    func isLastElementInPage(elementIndex: Int) -> Bool {
        return (elementIndex % pageSize) == 1
    }

    func isPageBeingSynced(page: Int) -> Bool {
        return pagesBeingSynced.contains(page)
    }

    func markAsUpdated(page: Int) {
        refreshDatePerPage[page] = Date()
    }

    func markAsBeingSynced(page: Int) {
        pagesBeingSynced.insert(page)
    }

    func unmarkAsBeingSynced(page: Int) {
        pagesBeingSynced.remove(page)
    }
}
