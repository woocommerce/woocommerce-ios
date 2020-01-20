import XCTest
import Foundation
@testable import WooCommerce
@testable import Networking


/// AggregateOrderItem Tests
///
final class AggregateDataHelperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 9876543210

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Verified that refunded products are calculated correctly.
    ///
    func testRefundedProductsCount() {
        
    }
}


extension AggregateDataHelperTests {
    /// Returns the OrderListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapOrders(from filename: String) -> [Order] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! OrderListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the OrderListMapper output upon receiving `orders-load-all`
    ///
    func mapLoadAllOrdersResponse() -> [Order] {
        return mapOrders(from: "orders-load-all")
    }
}
