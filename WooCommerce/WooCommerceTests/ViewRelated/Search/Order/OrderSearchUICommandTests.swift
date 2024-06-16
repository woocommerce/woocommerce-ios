import XCTest
import Yosemite
@testable import WooCommerce
import Storage

final class OrderSearchUICommandTests: XCTestCase {
    let siteID: Int64 = 12345
    private var storageManager: MockOrderStatusesStoresManager!

    override func setUpWithError() throws {
        super.setUp()
        storageManager = MockOrderStatusesStoresManager()
    }

    override func tearDownWithError() throws {
        storageManager = nil
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
        return orderStatus
    }
}
