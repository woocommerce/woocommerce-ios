import XCTest
@testable import WooCommerce


/// SyncingCoordinatorDelegate Closure-based Wrapper, for unit testing purposes.
///
private final class SyncingDelegateWrapper: SyncingCoordinatorDelegate {

    typealias SuccessCallback = (Bool) -> Void
    typealias OnSyncClosure = (Int, SuccessCallback?) -> Void

    var onSync: OnSyncClosure?

    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: ((Bool) -> Void)?) {
        onSync?(pageNumber, onCompletion)
    }
}

private final class CustomPagingDelegateWrapper: SyncingCoordinatorCustomPagingDelegate {
    let totalNumberOfVisibleElements: Int
    let hasSyncedLastPage: Bool

    init(totalNumberOfVisibleElements: Int = 0, hasSyncedLastPage: Bool = false) {
        self.totalNumberOfVisibleElements = totalNumberOfVisibleElements
        self.hasSyncedLastPage = hasSyncedLastPage
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

    // MARK: Tests with a custom paging delegate

    /// Verifies that `isLastElementInPage` returns true only when the elementIndex is effectively last one of the visible elements.
    ///
    func testIsLastElementInPageReturnsTrueOnlyForTheLastElementFromCustomPagingDelegate() {
        for testPageSize in 10...100 {
            let testCollectionSize = testPageSize * 2
            coordinator = SyncingCoordinator(pageSize: testPageSize)
            let totalNumberOfVisibleElements = testPageSize - 3
            let customPagingDelegate = CustomPagingDelegateWrapper(totalNumberOfVisibleElements: totalNumberOfVisibleElements)
            coordinator.customPagingDelegate = customPagingDelegate

            for elementIndex in 0..<testCollectionSize {
                let expectedOutput = elementIndex == (totalNumberOfVisibleElements - 1)
                let isLastElement = coordinator.isLastElementInPage(elementIndex: elementIndex)

                XCTAssertEqual(isLastElement, expectedOutput)
            }
        }
    }

    /// Verifies that `ensureNextPageIsSynchronized` synchronizes the next page for two pages given the last visible index.
    ///
    func testEnsuringNextPageIsSynchronizedForTwoPagesSyncsTwiceForTheLastElementFromCustomPagingDelegate() {
        // Given
        let pageSize = 25
        coordinator = SyncingCoordinator(pageFirstIndex: 1, pageSize: pageSize)
        coordinator.delegate = delegate

        let totalNumberOfVisibleElements = 20
        let customPagingDelegate = CustomPagingDelegateWrapper(totalNumberOfVisibleElements: totalNumberOfVisibleElements)
        coordinator.customPagingDelegate = customPagingDelegate

        // When
        var pagesToSync = [Int]()
        waitForExpectation(count: 2) { exp in
            delegate.onSync = { (page, callback) in
                pagesToSync.append(page)
                callback?(true)

                exp.fulfill()
            }

            let expectedLastIndexForTheFirstPage = totalNumberOfVisibleElements - 1
            coordinator.ensureNextPageIsSynchronized(lastVisibleIndex: pageSize - 1) // Won't trigger sync
            coordinator.ensureNextPageIsSynchronized(lastVisibleIndex: expectedLastIndexForTheFirstPage)

            let expectedLastIndexForTheSecondPage = totalNumberOfVisibleElements - 1
            coordinator.ensureNextPageIsSynchronized(lastVisibleIndex: expectedLastIndexForTheSecondPage)
        }

        // Then
        XCTAssertEqual(pagesToSync, [1, 2])
    }

    /// Verifies when the first `ensureNextPageIsSynchronized` fails, the second call syncs the same first page for the last visible index.
    ///
    func testWhenEnsuringNextPageIsSynchronizedFailsItSyncsTheSamePageForTheLastElementFromCustomPagingDelegate() {
        // Given
        let pageSize = 25
        coordinator = SyncingCoordinator(pageFirstIndex: 1, pageSize: pageSize)
        coordinator.delegate = delegate

        let totalNumberOfVisibleElements = 20
        let customPagingDelegate = CustomPagingDelegateWrapper(totalNumberOfVisibleElements: totalNumberOfVisibleElements)
        coordinator.customPagingDelegate = customPagingDelegate

        // When
        var pagesToSync = [Int]()
        waitForExpectation(count: 2) { exp in
            delegate.onSync = { (page, callback) in
                let success = pagesToSync.count == 1
                pagesToSync.append(page)
                callback?(success)

                exp.fulfill()
            }

            let expectedLastIndexForTheFirstPage = totalNumberOfVisibleElements - 1
            coordinator.ensureNextPageIsSynchronized(lastVisibleIndex: pageSize - 1) // Won't trigger sync
            coordinator.ensureNextPageIsSynchronized(lastVisibleIndex: expectedLastIndexForTheFirstPage)

            let expectedLastIndexForTheSecondPage = totalNumberOfVisibleElements - 1
            coordinator.ensureNextPageIsSynchronized(lastVisibleIndex: expectedLastIndexForTheSecondPage)
        }

        // Then
        XCTAssertEqual(pagesToSync, [1, 1])
    }

    /// Verifies when the custom paging delegate indicates that the last page has been synced, `ensureNextPageIsSynchronized` should not trigger syncing.
    ///
    func testEnsuringNextPageIsSynchronizedWhenLastPageHasBeenSyncedFromCustomPagingDelegate() {
        // Given
        let pageSize = 25
        coordinator = SyncingCoordinator(pageFirstIndex: 1, pageSize: pageSize)
        coordinator.delegate = delegate

        let totalNumberOfVisibleElements = 20
        let customPagingDelegate = CustomPagingDelegateWrapper(totalNumberOfVisibleElements: totalNumberOfVisibleElements, hasSyncedLastPage: true)
        coordinator.customPagingDelegate = customPagingDelegate

        // When
        delegate.onSync = { (page, callback) in
            XCTFail("Sync for page \(page) should not be triggered when the last page has been synced")
        }
        let lastVisibleIndex = totalNumberOfVisibleElements - 1
        coordinator.ensureNextPageIsSynchronized(lastVisibleIndex: lastVisibleIndex)

        // Then: the delegate's `onSync` block should not be triggered.
    }
}
