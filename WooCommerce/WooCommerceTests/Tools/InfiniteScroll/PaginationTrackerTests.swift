import XCTest
@testable import WooCommerce

final class PaginationTrackerTests: XCTestCase {
    private var paginationTracker: PaginationTracker!
    private var mockDelegate: MockPaginationTrackerDelegate!

    override func setUp() {
        super.setUp()
        mockDelegate = MockPaginationTrackerDelegate()
        paginationTracker = PaginationTracker(pageFirstIndex: 0, pageSize: 30)
        paginationTracker.delegate = mockDelegate
    }

    override func tearDown() {
        paginationTracker = nil
        mockDelegate = nil
        super.tearDown()
    }

    func test_ensuring_next_page_after_syncing_first_page_triggers_delegate_to_sync_two_pages() {
        // Arrange
        var syncedPages = [PageInformation]()
        mockDelegate.onSync = { pageInformation, onCompletion in
            syncedPages.append(pageInformation)
            onCompletion?(.success(true))
        }

        // Action
        paginationTracker.syncFirstPage()
        paginationTracker.ensureNextPageIsSynced()

        // Assert
        XCTAssertEqual(syncedPages, [
            .init(pageNumber: 0, pageSize: 30, reason: nil),
            .init(pageNumber: 1, pageSize: 30, reason: nil)
        ])
    }

    func test_ensuring_next_page_after_syncing_first_page_without_next_page_is_no_op() {
        // Arrange
        var syncedPages = [PageInformation]()
        mockDelegate.onSync = { pageInformation, onCompletion in
            syncedPages.append(pageInformation)
            onCompletion?(.success(false))
        }

        // Action
        paginationTracker.syncFirstPage()
        paginationTracker.ensureNextPageIsSynced()

        // Assert
        XCTAssertEqual(syncedPages, [
            .init(pageNumber: 0, pageSize: 30, reason: nil)
        ])
    }

    func test_resyncing_after_syncing_first_page_triggers_delegate_to_sync_the_first_page_again() {
        // Arrange
        var syncedPages = [PageInformation]()
        mockDelegate.onSync = { pageInformation, onCompletion in
            syncedPages.append(pageInformation)
            onCompletion?(.success(true))
        }

        // Action
        paginationTracker.syncFirstPage()
        paginationTracker.resync(reason: "Testing", onCompletion: nil)

        // Assert
        XCTAssertEqual(syncedPages, [
            .init(pageNumber: 0, pageSize: 30, reason: nil),
            .init(pageNumber: 0, pageSize: 30, reason: "Testing")
        ])
    }

    func test_ensuring_next_page_without_syncing_first_page_triggers_delegate_to_sync_the_first_page() {
        // Arrange
        var syncedPages = [PageInformation]()
        mockDelegate.onSync = { pageInformation, onCompletion in
            syncedPages.append(pageInformation)
            onCompletion?(.success(true))
        }

        // Action
        paginationTracker.ensureNextPageIsSynced()

        // Assert
        XCTAssertEqual(syncedPages, [.init(pageNumber: 0, pageSize: 30, reason: nil)])
    }

    func test_ensuring_next_page_after_syncing_first_page_with_failure_triggers_delegate_to_sync_the_first_page_twice() {
        // Arrange
        var syncedPages = [PageInformation]()
        mockDelegate.onSync = { pageInformation, onCompletion in
            syncedPages.append(pageInformation)
            onCompletion?(.failure(NSError(domain: "", code: 1, userInfo: nil)))
        }

        // Action
        paginationTracker.syncFirstPage()
        paginationTracker.ensureNextPageIsSynced()

        // Assert
        XCTAssertEqual(syncedPages, [
            .init(pageNumber: 0, pageSize: 30, reason: nil),
            .init(pageNumber: 0, pageSize: 30, reason: nil)
        ])
    }
}

private struct PageInformation: Equatable {
    let pageNumber: Int
    let pageSize: Int
    let reason: String?
}

/// `PaginationTrackerDelegate` Closure-based wrapper, for unit testing purposes.
///
private class MockPaginationTrackerDelegate: PaginationTrackerDelegate {
    typealias OnSyncClosure = (PageInformation, SyncCompletion?) -> Void

    var onSync: OnSyncClosure?

    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        onSync?(.init(pageNumber: pageNumber, pageSize: pageSize, reason: reason), onCompletion)
    }
}
