import XCTest
@testable import WooCommerce


/// SyncingCoordinatorDelegate Closure-based Wrapper, for unit testing purposes.
///
private class SyncingDelegateWrapper: SyncingCoordinatorDelegate {

    typealias SuccessCallback = (Bool) -> Void
    typealias OnSyncClosure = (Int, SuccessCallback?) -> Void

    var onSync: OnSyncClosure?

    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: ((Bool) -> Void)?) {
        onSync?(pageNumber, onCompletion)
    }
}


/// SyncCoordinator Tests
///
class SyncCoordinatorTests: XCTestCase {

    /// Quite self explanatory!
    ///
    private let secondPageNumber = SyncingCoordinator.Defaults.pageFirstIndex + 1

    /// Last element in the first page: Expected to trigger a Sync event
    ///
    private let lastElementInFirstPage = SyncingCoordinator.Defaults.pageSize -  1

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

        coordinator = SyncingCoordinator()
        coordinator.delegate = delegate
    }


    /// Verifies that `isLastElementInPage` returns true only when the elementIndex is effectively last one in it's page.
    ///
    func testIsLastElementInPageReturnsTrueWheneverTheReceivedElementIsEffectivelyTheLastOneInThePage() {
        for testPageSize in 10...100 {
            let testCollectionSize = testPageSize * 2
            coordinator = SyncingCoordinator(pageSize: testPageSize)

            for elementIndex in 0..<testCollectionSize {
                /// Note: YES this can be vastly improved. But the goal is to compare the output with an algorithm that's
                /// not exactly the same one implemented in `isLastElementInPage`, so we're verifying against known cases.
                ///
                let expectedOutput = elementIndex == (testPageSize - 1) || elementIndex == (testPageSize * 2 - 1)
                let isLastElement = coordinator.isLastElementInPage(elementIndex: elementIndex)

                XCTAssertEqual(isLastElement, expectedOutput)
            }
        }
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
