import XCTest
@testable import WooCommerce
@testable import Networking
@testable import Yosemite

final class ProductReviewsViewModelTests: XCTestCase {
    private var mockDataSource: ReviewsDataSource!
    private var viewModel: ProductReviewsViewModel!
    private let productID: Int64 = 12345

    override func setUp() {
        super.setUp()
        mockDataSource = MockProductReviewsDataSource()
        viewModel = ProductReviewsViewModel(siteID: 2, data: mockDataSource)
    }

    override func tearDown() {
        viewModel = nil
        mockDataSource = nil
        super.tearDown()
    }

    func test_dataSource_returns_injected_ProductReviewsDataSource() {
        let dataSource = viewModel.dataSource
        XCTAssertNotNil(dataSource as? MockProductReviewsDataSource)
    }

    func test_delegate_returns_injected_ProductReviewsDelegate() {
        let delegate = viewModel.delegate
        XCTAssertNotNil(delegate as? MockProductReviewsDataSource)
    }

    func test_isEmpty_returns_the_same_as_the_dataSource() {
        XCTAssertEqual(viewModel.isEmpty, mockDataSource.isEmpty)
    }

    func test_display_placeHolder_reviews_stops_forwarding_events_in_dataSource() {
        let table = UITableView()
        let ds = mockDataSource as! MockProductReviewsDataSource

        viewModel.displayPlaceholderReviews(tableView: table)

        XCTAssertTrue(ds.stopsForwardingEventsWasHit)
    }

    func test_remove_placeHolder_reviews_starts_forwarding_events_in_dataSource() {
        let table = UITableView()
        let ds = mockDataSource as! MockProductReviewsDataSource

        viewModel.removePlaceholderReviews(tableView: table)

        XCTAssertTrue(ds.startForwardingEventsWasHit)
    }

    func test_configure_resultsController_starts_forwarding_events_and_starts_observing_reviews_in_dataSource() {
        let table = UITableView()
        let ds = mockDataSource as! MockProductReviewsDataSource

        viewModel.configureResultsController(tableView: table)

        XCTAssertTrue(ds.startForwardingEventsWasHit && ds.startObservingWasHit)
    }

    func test_sync_data_hits_expected_reviews_and_products_actions() {
        let storesManager = MockProductReviewsStoresManager()
        ServiceLocator.setStores(storesManager)

        waitForExpectation { (expectation) in
            viewModel.synchronizeReviews(pageNumber: 1, pageSize: 25, productID: productID) {
                if storesManager.syncReviewsIsHit {
                    XCTAssertTrue(storesManager.syncReviewsIsHit)
                    expectation.fulfill()
                } else {
                    XCTFail()
                }
            }
        }
    }
}


// MARK: - Mocks

final class MockProductReviewsDataSource: NSObject, ReviewsDataSource {

    private lazy var reviews: [ProductReview] = {
        let mocks = MockReviews()
        let mockReview = mocks.review()
        return [mockReview, mockReview]
    }()

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

final class MockProductReviewsStoresManager: DefaultStoresManager {
    var syncReviewsIsHit = false

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
    }

    private func onReviewAction(_ action: ProductReviewAction) {
        switch action {
        case .synchronizeProductReviews(_, _, _, _, _, let onCompletion):
            syncReviewsIsHit = true
            onCompletion(nil)
        default:
            return
        }
    }
}
