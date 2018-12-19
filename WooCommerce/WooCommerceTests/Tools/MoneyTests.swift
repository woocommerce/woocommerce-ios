import XCTest
@testable import WooCommerce


/// Money Tests
///
class MoneyTests: XCTestCase {

    /// Test currency symbol lookup returns correctly encoded symbol.
    ///
    func testCurrencySymbol() {
        let money = Money(amount: 0.00, currency: .AED)
        let symbol = money.symbol
        XCTAssertEqual("د.إ", symbol)
    }
}
