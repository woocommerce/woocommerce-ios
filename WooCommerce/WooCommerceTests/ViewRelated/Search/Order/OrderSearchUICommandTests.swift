import XCTest

@testable import WooCommerce
import Storage
import Yosemite
import Networking

final class OrderSearchUICommandTests: XCTestCase {
    let siteID: Int64 = 12345
    private var storageManager: MockStorageManager!

    override func setUpWithError() throws {
        super.setUp()
        storageManager = MockStorageManager()
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
        let mockOrders = MockOrders()
        let mockOrder = mockOrders.sampleOrder() as Networking.Order

        // Create a local mock order status
        let mockOrderStatus = OrderStatus(
            name: "Processing",
            siteID: mockOrder.siteID,
            slug: "processing",
            total: 0
        )
        let command = OrderSearchUICommand(siteID: siteID, onSelectSearchResult: { _, _ in }, storageManager: storageManager)

        // Override the lookUpOrderStatus method to return the mock order status
        OrderSearchUICommand._lookUpOrderStatus = { (order: Networking.Order) in
            return mockOrderStatus
        }

        // When
        let cellViewModel = command.createCellViewModel(model: mockOrder)

        // Then
        XCTAssertNotNil(cellViewModel, "Expected createCellViewModel to return an OrderListCellViewModel instance")
        XCTAssertEqual(cellViewModel.statusString, mockOrderStatus.name, "Expected order status name to match")
    }
}
