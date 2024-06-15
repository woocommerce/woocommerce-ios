import XCTest

@testable import WooCommerce
import Yosemite

final class OrderSearchUICommandTests: XCTestCase {
    let siteID: Int64 = 12345

    override func setUpWithError() throws {
        super.setUp()
    }

    override func tearDownWithError() throws {
        super.tearDown()
    }

    func testCreateStarterViewControllerReturnsNil() throws {
        // Given
        let command = OrderSearchUICommand(siteID: siteID, onSelectSearchResult: { _, _ in })

        // When
        let starterViewController = command.createStarterViewController()

        // Then
        XCTAssertNil(starterViewController, "Expected createStarterViewController to return nil")
    }

    func testCreateResultsController() {
        // Given

        let command = OrderSearchUICommand(siteID: siteID, onSelectSearchResult: { _, _ in })

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
        let order = MockOrders().makeOrder()

        let command = OrderSearchUICommand(siteID: siteID, onSelectSearchResult: { _, _ in })

        // When
        let cellViewModel = command.createCellViewModel(model: order)

        // Then
        XCTAssertNotNil(cellViewModel, "Expected createCellViewModel to return an OrderListCellViewModel instance")
        XCTAssertEqual(cellViewModel.status, OrderStatusEnum.processing, "Expected order status to match")
    }

}
