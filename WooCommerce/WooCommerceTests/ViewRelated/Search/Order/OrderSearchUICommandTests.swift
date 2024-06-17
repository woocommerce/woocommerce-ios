import XCTest
import Yosemite
@testable import WooCommerce
import Storage
import Networking
import protocol WooFoundation.Analytics

final class OrderSearchUICommandTests: XCTestCase {
    let siteID: Int64 = 12345
    private var storageManager: MockOrderStatusesStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUpWithError() throws {
        super.setUp()
        storageManager = MockOrderStatusesStoresManager()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDownWithError() throws {
        storageManager = nil
        analyticsProvider = nil
        analytics = nil
        super.tearDown()
    }

    func testCreateStarterViewControllerReturnsNil() throws {
        // Given
        let command = OrderSearchUICommand(siteID: siteID, onSelectSearchResult: { _, _ in }, storageManager: storageManager)

        // When
        let starterViewController = command.createStarterViewController()

        // Then
        XCTAssertNil(starterViewController, "Expected createStarterViewController to return nil")
    }

    func testCreateResultsController() {
        // Given
        let command = OrderSearchUICommand(siteID: siteID, onSelectSearchResult: { _, _ in }, storageManager: storageManager)

        // When
        let resultsController = command.createResultsController()

        // Then
        XCTAssertNotNil(resultsController, "Expected createResultsController to return a ResultsController instance")
        XCTAssertEqual(resultsController.predicate?.predicateFormat, "siteID == \(siteID)", "Predicate format did not match")
        XCTAssertEqual(resultsController.sortDescriptors?.first?.key, "dateCreated", "First sort descriptor key did not match")
        XCTAssertEqual(resultsController.sortDescriptors?.first?.ascending, false, "First sort descriptor ascending did not match")
    }

    func testCreateCellViewModel() {
        // Given
        let mockOrder = MockOrders().makeOrder(status: .onHold, items: [], shippingLines: [], refunds: [], fees: [], taxes: [], customFields: [], giftCards: [])

        let command = OrderSearchUICommand(siteID: siteID, onSelectSearchResult: { _, _ in }, storageManager: storageManager)

        // Insert mock order statuses
        insertOrderStatuses()

        // When
        let cellViewModel = command.createCellViewModel(model: mockOrder)

        // Then
        XCTAssertNotNil(cellViewModel, "Expected createCellViewModel to return an OrderListCellViewModel instance")
        XCTAssertEqual(cellViewModel.statusString, "on-hold", "Expected order status name to match")
        XCTAssertEqual(cellViewModel.status, .onHold, "Expected createCellViewModel to return on hold status")
    }

    func testSanitizeKeyword() {
        // Given
        let command = OrderSearchUICommand(siteID: siteID, onSelectSearchResult: { _, _ in }, storageManager: storageManager)

        // When
        let sanitizedKeywordWithHash = command.sanitizeKeyword("#123")
        let sanitizedKeywordWithoutHash = command.sanitizeKeyword("123")

        // Then
        XCTAssertEqual(sanitizedKeywordWithHash, "123", "Expected sanitizeKeyword to remove the leading '#'")
        XCTAssertEqual(sanitizedKeywordWithoutHash, "123", "Expected sanitizeKeyword to return the keyword unchanged if there's no leading '#'")
    }

    func testSynchronizeModelsTracksAnalytics() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let command = OrderSearchUICommand(siteID: siteID, onSelectSearchResult: { _, _ in }, storageManager: storageManager, analytics: analytics, stores: stores)
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
            command.synchronizeModels(siteID: self.siteID, keyword: keyword, pageNumber: 1, pageSize: 20) { success in
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

    func testDidSelectSearchResult() throws {
        // Given
        let order = Networking.Order.fake().copy()

        // When
        let selectedOrder = waitFor { promise in
            let command = OrderSearchUICommand(siteID: self.siteID, onSelectSearchResult: { order, _ in
                promise(order)
            }, storageManager: storageManager)
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

    private func waitFor<T>(timeout: TimeInterval = 1, _ completion: (_ promise: @escaping (T) -> Void) -> Void) -> T? {
        var result: T?
        let expectation = self.expectation(description: "Waiting for completion")
        completion {
            result = $0
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
        return result
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
        return orderStatus
    }
}
