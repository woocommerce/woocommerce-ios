import XCTest
@testable import WooCommerce


/// SyncingCoordinatorDelegate Closure-based Wrapper, for unit testing purposes.
///
private class SyncingDelegateWrapper: SyncingCoordinatorDelegate {

    typealias SuccessCallback = (Bool) -> Void
    typealias OnSyncClosure = (Int, SuccessCallback?) -> Void

    var onSync: OnSyncClosure?

    func sync(pageNumber: Int, onCompletion: ((Bool) -> Void)?) {
        onSync?(pageNumber, onCompletion)
    }
}


/// SyncCoordinator Tests
///
class SyncCoordinatorTests: XCTestCase {

    /// Testing Page Size
    ///
    private let pageSize = 2

    /// Testing Page TTL
    ///
    private let pageTTLInSeconds = TimeInterval(2)

    /// Quite self explanatory!
    ///
    private let secondPageNumber =  2

    /// Last element in the first page: Expected to trigger a Sync event
    ///
    private let lastElementInFirstPage = 1

    /// Testing Delegate Wrapper
    ///
    private let delegate = SyncingDelegateWrapper()

    /// Testing Sync Coordinator
    ///
    private var coordinator: SyncingCoordinator!


    // MARK: - Overridden Methods
    //
    override func setUp() {
        super.setUp()

        coordinator = SyncingCoordinator(pageSize: pageSize, pageTTLInSeconds: pageTTLInSeconds)
        coordinator.delegate = delegate
    }


    /// Verifies that `ensureNextPageIsSynchronized` attempts to synchronize the second page, whenever the first page's last
    /// element is displayed.
    ///
    func testEnsureNextPageIsSynchronizedEffectivelyAttemptsToSynchronizeNextPage() {
        let expectation = self.expectation(description: "Sync Callback")
        delegate.onSync = { (page, callback) in
            XCTAssertEqual(page, self.secondPageNumber)
            callback?(true)

            expectation.fulfill()
        }

        coordinator.ensureNextPageIsSynchronized(lastVisibleIndex: lastElementInFirstPage)
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    /// Verifies that `ensureNextPageIsSynchronized` marks the second page's cache as valid, whenever the Sync'ing call was
    /// successful.
    ///
    func testEnsureNextPageIsSynchronizedMarksCacheAsValidOnSuccess() {
        let expectation = self.expectation(description: "Sync Callback")
        delegate.onSync = { (page, callback) in
            callback?(true)

            XCTAssertFalse(self.coordinator.isCacheInvalid(pageNumber: self.secondPageNumber))
            expectation.fulfill()
        }

        XCTAssertTrue(coordinator.isCacheInvalid(pageNumber: secondPageNumber))
        coordinator.ensureNextPageIsSynchronized(lastVisibleIndex: lastElementInFirstPage)
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    /// Verifies that `ensureNextPageIsSynchronized` does not mark the second page's cache as valid, whenever the Sync'ing
    /// call failed.
    ///
    func testEnsureNextPageIsSynchronizedMarksCacheAsValidOnError() {
        let expectation = self.expectation(description: "Sync Callback")
        delegate.onSync = { (page, callback) in
            callback?(false)

            XCTAssertTrue(self.coordinator.isCacheInvalid(pageNumber: self.secondPageNumber))
            expectation.fulfill()
        }

        XCTAssertTrue(coordinator.isCacheInvalid(pageNumber: secondPageNumber))
        coordinator.ensureNextPageIsSynchronized(lastVisibleIndex: lastElementInFirstPage)
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    /// Verifies that the SyncingCoordinator effectively keeps tabs of which pages are being sync'ed
    ///
    func testEnsureNextPageIsSynchronizedEffectivelyTracksPagesBeingSynced() {
        let expectation = self.expectation(description: "Sync Callback")
        delegate.onSync = { (page, callback) in

            XCTAssertTrue(self.coordinator.isPageBeingSynced(pageNumber: self.secondPageNumber))
            callback?(false)

            XCTAssertFalse(self.coordinator.isPageBeingSynced(pageNumber: self.secondPageNumber))
            expectation.fulfill()
        }

        XCTAssertFalse(coordinator.isPageBeingSynced(pageNumber: secondPageNumber))
        coordinator.ensureNextPageIsSynchronized(lastVisibleIndex: lastElementInFirstPage)
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }
}
