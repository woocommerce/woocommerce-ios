import XCTest
@testable import WooCommerce


/// Currency Tests
///
class CurrencyTests: XCTestCase {
    /// Test currency symbol lookup returns correctly encoded symbol.
    ///
    func testCurrencySymbol() {
        let symbol = Currency().symbol(from: .AED)
        XCTAssertEqual("د.إ", symbol)
    }
}
