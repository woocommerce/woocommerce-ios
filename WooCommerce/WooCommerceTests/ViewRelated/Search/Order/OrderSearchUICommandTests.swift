import XCTest
import Yosemite
@testable import WooCommerce
import Storage
import protocol WooFoundation.Analytics

final class OrderSearchUICommandTests: XCTestCase {
    let siteID: Int64 = 12345
    private var storageManager: MockOrderStatusesStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var systemUnderTest: OrderSearchUICommand!

    override func setUp() {
        super.setUp()
        storageManager = MockOrderStatusesStoresManager()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        systemUnderTest = OrderSearchUICommand(siteID: siteID, onSelectSearchResult: { _, _ in }, storageManager: storageManager)
    }

    override func tearDown() {
        storageManager = nil
        analyticsProvider = nil
        analytics = nil
        systemUnderTest = nil
        super.tearDown()
    }

    func test_createStarterViewController_returns_nil_so_empty_results_table_shown_before_search() {
        // When
        let starterViewController = systemUnderTest.createStarterViewController()

        // Then
        XCTAssertNil(starterViewController, "Expected createStarterViewController to return nil so that the empty results table will be shown before the search.")
    }

    func test_createResultsController_returns_results_controller_with_correct_predicate_and_sort_options() {
        // When
        let resultsController = systemUnderTest.createResultsController()

        // Then
        XCTAssertNotNil(resultsController, "Expected createResultsController to return a ResultsController instance")
        XCTAssertEqual(resultsController.predicate?.predicateFormat, "siteID == \(siteID)", "Predicate format did not match")
        XCTAssertEqual(resultsController.sortDescriptors?.first?.key, "dateCreated", "First sort descriptor key did not match")
        XCTAssertEqual(resultsController.sortDescriptors?.first?.ascending, false, "First sort descriptor ascending did not match")
    }

    func test_CreateCellViewModel() {
        // Given
        let mockOrder = MockOrders().makeOrder(status: .onHold)

        // Insert mock order statuses
        insertOrderStatuses()

        // When
        let cellViewModel = systemUnderTest.createCellViewModel(model: mockOrder)

        // Then
        XCTAssertNotNil(cellViewModel, "Expected createCellViewModel to return an OrderListCellViewModel instance")
        XCTAssertEqual(cellViewModel.status, .onHold, "Expected createCellViewModel to return on hold status")
    }

    func test_SanitizeKeyword_removing_leading_pound_symbol() {
        // When
        let sanitizedKeywordWithHash = systemUnderTest.sanitizeKeyword("#123")
        let sanitizedKeywordWithoutHash = systemUnderTest.sanitizeKeyword("123")

        // Then
        XCTAssertEqual(sanitizedKeywordWithHash, "123", "Expected sanitizeKeyword to remove the leading '#'")
        XCTAssertEqual(sanitizedKeywordWithoutHash, "123", "Expected sanitizeKeyword to return the keyword unchanged if there's no leading '#'")
    }

    func test_SynchronizeModels_tracks_orders_list_search_analytics() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let systemUnderTestWithMockedAnalytics = OrderSearchUICommand(siteID: siteID, onSelectSearchResult: { _, _ in }, storageManager: storageManager,
                                                                      analytics: analytics, stores: stores)
        let keyword = "testKeyword"
        stores.whenReceivingAction(ofType: OrderAction.self) { (action: OrderAction) in
            guard case let .searchOrders(_, _, _, _, onCompletion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            onCompletion(nil)
        }

        // Mock order statuses
        insertOrderStatuses()

        // When
        waitFor { promise in
            systemUnderTestWithMockedAnalytics.synchronizeModels(siteID: self.siteID, keyword: keyword, pageNumber: 1, pageSize: 20) { success in
                promise(())
            }
        }

        // Then
        guard let event = analyticsProvider.receivedEvents.first else {
            XCTFail("Expected an event but found none")
            return
        }
        XCTAssertEqual(event, "orders_list_search")

        guard let eventProperties = analyticsProvider.receivedProperties.first else {
            XCTFail("Expected event properties but found none")
            return
        }
        XCTAssertEqual(eventProperties["search"] as? String, keyword)
    }

    func test_DidSelectSearchResult_selects_correct_order() throws {
        // Given
        let order = Order.fake()

        // When
        let selectedOrder = waitFor { promise in
            let command = OrderSearchUICommand(siteID: self.siteID, onSelectSearchResult: { order, _ in
                promise(order)
            }, storageManager: self.storageManager)
            command.didSelectSearchResult(model: order, from: .init(), reloadData: {}, updateActionButton: {})
        }

        // Then
        XCTAssertEqual(selectedOrder, order)
    }

    private func insertOrderStatuses() {
        let statuses: [OrderStatusEnum] = [.pending, .processing, .onHold, .completed, .cancelled, .failed, .custom("aCustomStatus")]
        statuses.forEach { status in
            storageManager.insertOrderStatus(name: status.rawValue)
        }
        storageManager.viewStorage.saveIfNeeded()
    }
}

/// Mock Order Statuses Store Manager
///
private final class MockOrderStatusesStoresManager: MockStorageManager {
    fileprivate static let siteID: Int64 = 12345

    /// Inserts an order status
    ///
    @discardableResult
    func insertOrderStatus(name: String) -> StorageOrderStatus {
        let orderStatus = viewStorage.insertNewObject(ofType: StorageOrderStatus.self)
        orderStatus.name = name
        orderStatus.slug = name
        orderStatus.siteID = MockOrderStatusesStoresManager.siteID
        viewStorage.saveIfNeeded()
        return orderStatus
    }
}
