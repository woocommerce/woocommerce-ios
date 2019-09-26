import XCTest
@testable import WooCommerce
@testable import Networking
@testable import Yosemite

final class ReviewsViewModelTests: XCTestCase {
    private var mockDataSource: ReviewsDataSource!
    private var viewModel: ReviewsViewModel!

    override func setUp() {
        super.setUp()
        mockDataSource = MockReviewsDataSource()
        viewModel = ReviewsViewModel(data: mockDataSource)
    }

    override func tearDown() {
        viewModel = nil
        mockDataSource = nil
        super.tearDown()
    }

    func testDataSourceReturnsInjectedReviewsDataSource() {
        let dataSource = viewModel.dataSource
        XCTAssertNotNil(dataSource as? MockReviewsDataSource)
    }

    func testDelegateReturnsInjectedReviewsDelegate() {
        let delegate = viewModel.delegate
        XCTAssertNotNil(delegate as? MockReviewsDataSource)
    }

    func testIsEmptyReturnsTheSameAsTheDataSource() {
        XCTAssertEqual(viewModel.isEmpty, mockDataSource.isEmpty)
    }

    func testDisplayPlaceHolderReviewsStopsForWardingEventsInDataSource() {
        let table = UITableView()
        let ds = mockDataSource as! MockReviewsDataSource

        viewModel.displayPlaceholderReviews(tableView: table)

        XCTAssertTrue(ds.stopsForwardingEventsWasHit)
    }

    func testRemovePlaceHolderReviewsStartsForWardingEventsInDataSource() {
        let table = UITableView()
        let ds = mockDataSource as! MockReviewsDataSource

        viewModel.removePlaceholderReviews(tableView: table)

        XCTAssertTrue(ds.startForwardingEventsWasHit)
    }

    func testConfigureResultsControllerStartsForWardingEventsAndStartsObservingReviewsInDataSource() {
        let table = UITableView()
        let ds = mockDataSource as! MockReviewsDataSource

        viewModel.configureResultsController(tableView: table)

        XCTAssertTrue(ds.startForwardingEventsWasHit && ds.startObservingWasHit)
    }

    func testSyncDataHitsExpectedReviewsAndProductsActions() {
        let storesManager = MockReviewsStoresManager()
        ServiceLocator.setStores(storesManager)

        let expec = expectation(description: "Wait for synchronizeReviews to complete")

        viewModel.synchronizeReviews {
            let allTargetsHit = storesManager.syncReviewsIsHit && storesManager.retrieveProductsIsHit
            XCTAssertTrue(allTargetsHit)
            if allTargetsHit {
                expec.fulfill()
            } else {
                XCTFail()
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
}


// MARK: - Mocks

final class MockReviewsDataSource: NSObject, ReviewsDataSource {
    private lazy var reviews: [ProductReview] = {
        let mocks = MockReviews()
        let mockReview = mocks.review()
        return [mockReview, mockReview]
    }()

    var isEmpty: Bool {
        return reviews.isEmpty
    }

    var reviewsProductsIDs: [Int] {
        return reviews
            .map { return $0.productID }
            .uniqued()
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
}

final class MockReviewsStoresManager: DefaultStoresManager {
    var syncReviewsIsHit = false
    var retrieveProductsIsHit = false

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
    }

    private func onReviewAction(_ action: ProductReviewAction) {
        switch action {
        case .synchronizeProductReviews(_, _, _, let onCompletion):
            syncReviewsIsHit = true
            onCompletion(nil)
        default:
            return
        }
    }

    private func onProductAction(_ action: ProductAction) {
        switch action {
        case .retrieveProducts(_, _, onCompletion: let onCompletion):
            retrieveProductsIsHit = true
            onCompletion(nil)
        default:
            return
        }
    }
}
