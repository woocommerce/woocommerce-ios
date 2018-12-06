import XCTest
@testable import WooCommerce


/// Data+Woo: Unit Tests
///
class DataWooTests: XCTestCase {

    /// Verifies that `.hexString` returns the receiver, as a Hexadecimal encoded String.
    ///
    func testDataEncodedAsHexaStringReturnsExpeectedValue() {
        let data = Data(base64Encoded: "T6lj2yz8gksNZ3QO0rHAtHLM6Or8uCGEkFNh64i+Vbk=")
        XCTAssertEqual(data?.hexString, "4fa963db2cfc824b0d67740ed2b1c0b472cce8eafcb82184905361eb88be55b9")
    }
}
