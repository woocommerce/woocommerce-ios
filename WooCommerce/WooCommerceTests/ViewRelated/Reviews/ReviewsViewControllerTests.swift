import XCTest
@testable import WooCommerce

/// Tests for `ReviewsViewController`.
///
final class ReviewsViewControllerTests: XCTestCase {
    private var mockViewModel: MockReviewsViewModel!
    private var sut: ReviewsViewController!

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockViewModel = MockReviewsViewModel(siteID: 123)
        sut = ReviewsViewController(viewModel: mockViewModel)
    }

    override func tearDownWithError() throws {
        mockViewModel = nil
        sut = nil

        try super.tearDownWithError()
    }

    func test_menu_bar_button_item_is_not_present_if_there_are_no_unread_notifications() {
        // When
        mockViewModel.hasUnreadNotifications = false
        sut.makeViewAppear()

        // Then
        XCTAssertNil(sut.navigationItem.rightBarButtonItem)
    }

    func test_menu_bar_button_item_is_visible_if_there_are_unread_notifications_available() throws {
        // When
        mockViewModel.hasUnreadNotifications = true
        sut.makeViewAppear()

        // Then
        let markAllAsReadyButton = try XCTUnwrap(sut.navigationItem.rightBarButtonItem)
        XCTAssertEqual(markAllAsReadyButton.accessibilityIdentifier, "reviews-open-menu-button")
    }
}

// MARK: ReviewsViewController helpers
//
private extension ReviewsViewController {
    func makeViewAppear() {
        loadViewIfNeeded()
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
}

// MARK: Mocks
//
private final class MockReviewsViewModel: ReviewsViewModelOutput, ReviewsViewModelActionsHandler {

    private let data: ReviewsDataSource

    init(siteID: Int64) {
        self.data = DefaultReviewsDataSource(siteID: siteID)
    }

    // `ReviewsViewModelOutput` conformance
    //
    var isEmpty: Bool {
        data.isEmpty
    }

    var dataSource: UITableViewDataSource {
        data
    }

    var delegate: ReviewsInteractionDelegate {
        data
    }

    var hasUnreadNotifications = true

    var shouldPromptForAppReview = false

    var hasErrorLoadingData = true

    func containsMorePages(_ highestVisibleReview: Int) -> Bool { false }

    // Empty methods for `ReviewsViewModelActionsHandler` conformance
    //
    func displayPlaceholderReviews(tableView: UITableView) {}

    func removePlaceholderReviews(tableView: UITableView) {}

    func configureResultsController(tableView: UITableView) {}

    func refreshResults() {}

    func configureTableViewCells(tableView: UITableView) {}

    func markAllAsRead(onCompletion: @escaping (Error?) -> Void) {}

    func synchronizeReviews(pageNumber: Int, pageSize: Int, onCompletion: (() -> Void)?) {}
}
