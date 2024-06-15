import XCTest

@testable import WooCommerce
import Yosemite

final class OrderSearchUICommandTests: XCTestCase {

    override func setUpWithError() throws {
        super.setUp()
    }

    override func tearDownWithError() throws {
        super.tearDown()
    }

    func testCreateStarterViewControllerReturnsNil() throws {
        // Given
        let command = OrderSearchUICommand(siteID: 12345, onSelectSearchResult: { _, _ in })

        // When
        let starterViewController = command.createStarterViewController()

        // Then
        XCTAssertNil(starterViewController, "Expected createStarterViewController to return nil")
    }

}
