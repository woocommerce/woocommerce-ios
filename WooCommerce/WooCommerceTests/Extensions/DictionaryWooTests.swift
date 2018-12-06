import XCTest


/// Dictionary+Woo Unit Tests
///
class DictionaryWooTests: XCTestCase {

    private let sampleKey = "key"

    /// Verifies that a Float is effectively returned as a String Value, when retrieved via `string(forKey:)`
    ///
    func testStringForKeyReturnsStringValueWheneverTheValueIsStoredAsFloat() {
        let sample = [sampleKey: 3.14]
        XCTAssertEqual(sample.string(forKey: sampleKey), "3.14")
    }

    /// Verifies that an Integer is effectively returned as a String Value, when retrieved via `string(forKey:)`
    ///
    func testStringForKeyReturnsStringValueWheneverTheValueIsStoredAsInteger() {
        let sample = [sampleKey: 314]
        XCTAssertEqual(sample.string(forKey: "key"), "314")
    }

    /// Verifies that a String is effectively returned as a String Value, when retrieved via `string(forKey:)`
    ///
    func testStringForKeyReturnsStringValueWheneverTheValueIsStoredAsString() {
        let sample = [sampleKey: "3.14"]
        XCTAssertEqual(sample.string(forKey: sampleKey), "3.14")
    }
}
