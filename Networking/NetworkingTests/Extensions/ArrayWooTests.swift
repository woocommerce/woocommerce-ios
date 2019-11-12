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
        let actual = exampleIDs.sortedUniqueIntToString()

        XCTAssertEqual(expected, actual)
    }

    /// Verifies that a single value in an array produces a valid String.
    ///
    func testArrayWithSingleValueReturnsAString() {
        let exampleIDs = [999]
        let expected = "999"
        let actual = exampleIDs.sortedUniqueIntToString()

        XCTAssertEqual(expected, actual)
    }

    /// Verifies that an empty array produces an emtpy String.
    ///
    func testEmptyArrayReturnsAnEmptyString() {
        let exampleIDs = [Int]()
        let expected = ""
        let actual = exampleIDs.sortedUniqueIntToString()

        XCTAssertEqual(expected, actual)
    }

    /// Verifies that an array with int values produces a valid String.
    ///
    func testArrayWithValuesReturnsSortedValuesAsString() {
        let exampleIDs = [75, 37, 259, 16, 83]
        let expected = "16,37,75,83,259"
        let actual = exampleIDs.sortedUniqueIntToString()

        XCTAssertEqual(expected, actual)
    }

    /// Verifies that an array with duplicate entries produces a de-duplicated, valid String.
    ///
    func testArrayWithDuplicateValuesReturnsWithNoDuplicates() {
        let exampleIDs = [123, 6, 13, 259, 3, 321, 7, 6, 87, 3, 9, 17, 85, 87]
        let expected = "3,6,7,9,13,17,85,87,123,259,321"
        let actual = exampleIDs.sortedUniqueIntToString()

        XCTAssertEqual(expected, actual)
    }
}
