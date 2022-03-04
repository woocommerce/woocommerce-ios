import XCTest
@testable import WooCommerce
@testable import Networking
@testable import Yosemite

final class ReviewsViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 1334

    func testDataSourceReturnsInjectedReviewsDataSource() {
        // Given
        let mockDataSource = MockReviewsDataSource()
        let viewModel = ReviewsViewModel(siteID: sampleSiteID, data: mockDataSource)

        // When
        let dataSource = viewModel.dataSource

        // Then
        XCTAssertNotNil(dataSource as? MockReviewsDataSource)
    }

    func testDelegateReturnsInjectedReviewsDelegate() {
        // Given
        let mockDataSource = MockReviewsDataSource()
        let viewModel = ReviewsViewModel(siteID: sampleSiteID, data: mockDataSource)

        // When
        let delegate = viewModel.delegate

        // Then
        XCTAssertNotNil(delegate as? MockReviewsDataSource)
    }

    func testIsEmptyReturnsTheSameAsTheDataSource() {
        // Given
        let mockDataSource = MockReviewsDataSource()
        let viewModel = ReviewsViewModel(siteID: sampleSiteID, data: mockDataSource)

        // Then
        XCTAssertEqual(viewModel.isEmpty, mockDataSource.isEmpty)
    }

    func testDisplayPlaceHolderReviewsStopsForWardingEventsInDataSource() {
        // Given
        let table = UITableView()
        let mockDataSource = MockReviewsDataSource()
        let viewModel = ReviewsViewModel(siteID: sampleSiteID, data: mockDataSource)
        viewModel.displayPlaceholderReviews(tableView: table)

        // Then
        XCTAssertTrue(mockDataSource.stopsForwardingEventsWasHit)
    }

    func testRemovePlaceHolderReviewsStartsForWardingEventsInDataSource() {
        // Given
        let table = UITableView()
        let mockDataSource = MockReviewsDataSource()
        let viewModel = ReviewsViewModel(siteID: sampleSiteID, data: mockDataSource)

        // When
        viewModel.removePlaceholderReviews(tableView: table)

        // Then
        XCTAssertTrue(mockDataSource.startForwardingEventsWasHit)
    }

    func testConfigureResultsControllerStartsForWardingEventsAndStartsObservingReviewsInDataSource() {
        // Given
        let table = UITableView()
        let mockDataSource = MockReviewsDataSource()
        let viewModel = ReviewsViewModel(siteID: sampleSiteID, data: mockDataSource)

        // When
        viewModel.configureResultsController(tableView: table)

        // Then
        XCTAssertTrue(mockDataSource.startForwardingEventsWasHit && mockDataSource.startObservingWasHit)
    }

    func testSyncDataHitsExpectedReviewsAndProductsActions() {
        // Given
        let storesManager = MockReviewsStoresManager()
        let mockDataSource = MockReviewsDataSource()
        let viewModel = ReviewsViewModel(siteID: sampleSiteID, data: mockDataSource, stores: storesManager)

        // Then
        let expectation = expectation(description: "Wait for synchronizeReviews to complete")
        viewModel.synchronizeReviews(pageNumber: 1, pageSize: 25) {
            let allTargetsHit = storesManager.syncReviewsIsHit && storesManager.retrieveProductsIsHit
            XCTAssertTrue(allTargetsHit)
            if allTargetsHit {
                expectation.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func test_hasErrorLoadingData_false_after_successful_sync() {
        // Given
        let mockDataSource = MockReviewsDataSource()
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        storesManager.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            switch action {
            case .synchronizeProductReviews(_, _, _, _, _, let onCompletion):
                onCompletion(.success([MockReviews().review()]))
            default:
                return
            }
        }
        let viewModel = ReviewsViewModel(siteID: sampleSiteID, data: mockDataSource, stores: storesManager)
        viewModel.hasErrorLoadingData = true

        // When
        viewModel.synchronizeReviews(pageNumber: 1, pageSize: 25, onCompletion: nil)

        // Then
        XCTAssertFalse(viewModel.hasErrorLoadingData)
    }

    func test_hasErrorLoadingData_true_after_failed_sync() {
        // Given
        let mockDataSource = MockReviewsDataSource()
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        storesManager.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            switch action {
            case .synchronizeProductReviews(_, _, _, _, _, let onCompletion):
                onCompletion(.failure(SampleError.first))
            default:
                return
            }
        }
        let viewModel = ReviewsViewModel(siteID: sampleSiteID, data: mockDataSource, stores: storesManager)
        viewModel.hasErrorLoadingData = false

        // When
        viewModel.synchronizeReviews(pageNumber: 1, pageSize: 25, onCompletion: nil)

        // Then
        XCTAssertTrue(viewModel.hasErrorLoadingData)
    }

    func test_synchronizeReviews_triggers_retrieveProducts_with_all_reviewsProductIDs() {
        // Given
        let mockDataSource = MockReviewsDataSource()
        let mocks = MockReviews()
        let sampleReviews: [ProductReview] = [
            mocks.review(injectedReviewID: sampleSiteID, injectedProductID: 55),
            mocks.review(injectedReviewID: sampleSiteID, injectedProductID: 668),
            mocks.review(injectedReviewID: sampleSiteID, injectedProductID: 789)
        ]

        let mockStores = MockStoresManager(sessionManager: .makeForTesting())
        mockStores.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            switch action {
            case let .synchronizeProductReviews(_, _, _, _, _, onCompletion):
                onCompletion(.success(sampleReviews))
            default:
                break
            }
        }

        mockStores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case .synchronizeNotifications(let onCompletion):
                onCompletion(nil)
            default:
                break
            }
        }

        var retrievedProductIDs: [Int64] = []
        mockStores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProducts(_, productIDs, _, _, onCompletion):
                retrievedProductIDs = productIDs
                onCompletion(.success((products: [], hasNextPage: false)))
            default:
                break
            }
        }
        let viewModel = ReviewsViewModel(siteID: sampleSiteID, data: mockDataSource, stores: mockStores)

        // When
        let expectation = expectation(description: "Wait for synchronizeReviews to complete")
        viewModel.synchronizeReviews(pageNumber: 1, pageSize: 25) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)

        // Then
        XCTAssertEqual(retrievedProductIDs, [55, 668, 789])
    }
}


// MARK: - Mocks

final class MockReviewsDataSource: NSObject, ReviewsDataSource {

    var reviews: [ProductReview] = []

    var isEmpty: Bool {
        return reviews.isEmpty
    }

    var reviewCount: Int {
        return reviews.count
    }

    var reviewsProductsIDs: [Int64] {
        return reviews
            .map { return $0.productID }
            .uniqued()
    }

    var notifications: [Note] {
        return []
    }

    var startForwardingEventsWasHit = false
    var stopsForwardingEventsWasHit = false
    var startObservingWasHit = false

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    func observeReviews() throws {
        startObservingWasHit = true
    }

    func startForwardingEvents(to tableView: UITableView) {
        startForwardingEventsWasHit = true
    }

    func stopForwardingEvents() {
        stopsForwardingEventsWasHit = true
    }

    func didSelectItem(at indexPath: IndexPath, in viewController: UIViewController) {}

    func presentReviewDetails(for noteID: Int64, in viewController: UIViewController) {}

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath,
                   with syncingCoordinator: SyncingCoordinator) {}

    func refreshDataObservers() {}

}

final class MockReviewsStoresManager: DefaultStoresManager {
    var syncReviewsIsHit = false
    var retrieveProductsIsHit = false
    var syncNotificationsIsHit = false

    init() {
        let sessionManager = SessionManager.testingInstance
        sessionManager.setStoreId(123)
        super.init(sessionManager: sessionManager)
    }

    // MARK: - Overridden Methods
    override func dispatch(_ action: Action) {
        if let productReviewAction = action as? ProductReviewAction {
            onReviewAction(productReviewAction)
        }

        if let productAction = action as? ProductAction {
            onProductAction(productAction)
        }

        if let notificationAction = action as? NotificationAction {
            onNotificationAction(notificationAction)
        }
    }

    private func onReviewAction(_ action: ProductReviewAction) {
        switch action {
        case .synchronizeProductReviews(_, _, _, _, _, let onCompletion):
            syncReviewsIsHit = true
            onCompletion(.success([MockReviews().review()]))
        default:
            return
        }
    }

    private func onProductAction(_ action: ProductAction) {
        switch action {
        case .retrieveProducts(_, _, _, _, onCompletion: let onCompletion):
            retrieveProductsIsHit = true
            onCompletion(.success((products: [], hasNextPage: false)))
        default:
            return
        }
    }

    private func onNotificationAction(_ action: NotificationAction) {
        switch action {
        case .synchronizeNotifications(let onCompletion):
            syncNotificationsIsHit = true
            onCompletion(nil)
        default:
            return
        }
    }
}
