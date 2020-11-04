import XCTest
@testable import WooCommerce

final class PresenceThresholdFilterTests: XCTestCase {
    func test_appending_a_sequence_of_values() {
        let sequence = PresenceThresholdFilter<String>(threshold: 0.5, outOf: 6)
        // ["hello"]
        XCTAssertEqual(sequence.append(value: "hello"), "hello")
        // ["hello", "hello"] repeat frequency: 1.0
        XCTAssertEqual(sequence.append(value: "hello"), nil)
        // ["hello", "hello", "hey"] repeat frequency: 0
        XCTAssertEqual(sequence.append(value: "hey"), "hey")
        // ["hello", "hello", "hey", "hello"] repeat frequency: 3/4 = 0.75
        XCTAssertEqual(sequence.append(value: "hello"), nil)
        // ["hello", "hello", "hey", "hello", "hey"] repeat frequency: 2/5 = 0.4
        XCTAssertEqual(sequence.append(value: "hey"), "hey")
        // ["hello", "hello", "hey", "hello", "hey", "hey"] repeat frequency: 3/6 = 0.5 (max)
        XCTAssertEqual(sequence.append(value: "hey"), "hey")
        // ["hello", "hey", "hello", "hey", "hey", "hello"] repeat frequency: 3/6 = 0.5 (max)
        XCTAssertEqual(sequence.append(value: "hello"), "hello")
    }
}
