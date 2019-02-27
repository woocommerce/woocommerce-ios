
import XCTest
@testable import WooCommerce

final class OrderTrackingTableViewCellTests: XCTestCase {
    private var cell: OrderTrackingTableViewCell?

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("OrderTrackingTableViewCell", owner: self, options: nil)
        cell = nib?.first as? OrderTrackingTableViewCell
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}
