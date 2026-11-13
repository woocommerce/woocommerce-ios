import XCTest
@testable import WooCommerce
@testable import Networking
@testable import Yosemite

final class ProductReviewsViewModelTests: XCTestCase {
    private let productID: Int64 = 12345

    @MainActor
    func test_dataSource_returns_injected_ProductReviewsDataSource() {
        let (viewModel, _) = makeSUT()
        let dataSource = viewModel.dataSource
        XCTAssertNotNil(dataSource as? MockProductReviewsDataSource)
    }

    @MainActor
    func test_delegate_returns_injected_ProductReviewsDelegate() {
        let (viewModel, _) = makeSUT()
        let delegate = viewModel.delegate
        XCTAssertNotNil(delegate as? MockProductReviewsDataSource)
    }

    @MainActor
    func test_isEmpty_returns_the_same_as_the_dataSource() {
        let (viewModel, mockDataSource) = makeSUT()
        XCTAssertEqual(viewModel.isEmpty, mockDataSource.isEmpty)
    }

    @MainActor
    func test_configure_resultsController_starts_forwarding_events_and_starts_observing_reviews_in_dataSource() {
        let (viewModel, mockDataSource) = makeSUT()
        let table = UITableView()

        viewModel.configureResultsController(tableView: table)

        XCTAssertTrue(mockDataSource.startForwardingEventsWasHit && mockDataSource.startObservingWasHit)
    }

    @MainActor
    func test_sync_data_hits_expected_reviews_and_products_actions() {
        let (viewModel, _) = makeSUT()
        let storesManager = MockProductReviewsStoresManager()
        ServiceLocator.setStores(storesManager)

        waitForExpectation { expectation in
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

private extension ProductReviewsViewModelTests {
    @MainActor
    func makeSUT() -> (viewModel: ProductReviewsViewModel, mockDataSource: MockProductReviewsDataSource) {
        let mockDataSource = MockProductReviewsDataSource()
        let viewModel = ProductReviewsViewModel(siteID: 2, data: mockDataSource)
        return (viewModel, mockDataSource)
    }
}


// MARK: - Mocks

@MainActor
final class MockProductReviewsDataSource: NSObject, ReviewsDataSourceProtocol {

    private lazy var reviews: [ProductReview] = {
        return [.fake()]
    }()

    let supportsWPComNotifications: Bool = true

    var isEmpty: Bool {
        return reviews.isEmpty
    }

    var reviewCount: Int {
        return reviews.count
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
            onCompletion(.success([]))
        default:
            return
        }
    }
}
