import XCTest
@testable import WooCommerce

final class SequenceHelpersTests: XCTestCase {
    // MARK: - `removingDuplicates`
    func testRemovingDuplicatesFromAnArrayOfMultipleDuplicatesReturnsAnArrayOfUniqueElementsInTheSameOrder() {
        let array = ["Woo", "woo", "Woo", "woo", "Woody"]
        XCTAssertEqual(array.removingDuplicates(), ["Woo", "woo", "Woody"])
    }

    func testRemovingDuplicatesFromAnArrayWithoutDuplicatesReturnsTheSameArray() {
        let array = ["Woo", "woo", "woody"]
        XCTAssertEqual(array.removingDuplicates(), array)
    }

    func testRemovingDuplicatesFromAnEmptyArrayReturnsTheSameArray() {
        let array = [Int]()
        XCTAssertEqual(array.removingDuplicates(), array)
    }
}
