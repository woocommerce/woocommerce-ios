import XCTest
@testable import Networking


/// Array+Woo Unit Tests
///
class ArrayWooTests: XCTestCase {

    /// Verifies that a zero value in an array produces a valid String.
    ///
    func testArrayWithZeroValueReturnsAString() {
        let exampleIDs = [0]
        let expected = "0"
        let actual = exampleIDs.intToString()

        XCTAssertEqual(expected, actual)
    }

    /// Verifies that a single value in an array produces a valid String.
    ///
    func testArrayWithSingleValueReturnsAString() {
        let exampleIDs = [999]
        let expected = "999"
        let actual = exampleIDs.intToString()

        XCTAssertEqual(expected, actual)
    }

    /// Verifies that an empty array produces an emtpy String.
    ///
    func testEmptyArrayReturnsAnEmptyString() {
        let exampleIDs = [Int]()
        let expected = ""
        let actual = exampleIDs.intToString()

        XCTAssertEqual(expected, actual)
    }

    /// Verifies that an array with int values produces a valid String.
    ///
    func testArrayWithValuesReturnsSortedValuesAsString() {
        let refundIDs = [75, 37, 259, 16, 83]
        let expected = "16,37,75,83,259"
        let actual = refundIDs.intToString()

        XCTAssertEqual(expected, actual)
    }
}
