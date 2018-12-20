import XCTest
@testable import WooCommerce


/// Money Tests
///
class CurrencyTests: XCTestCase {

    /// Test currency symbol lookup returns correctly encoded symbol.
    ///
    func testCurrencySymbol() {
        let currency = Currency(amount: "0.00", code: .AED, position: .left)
        let symbol = currency.symbol
        XCTAssertEqual("د.إ", symbol)
    }
}
