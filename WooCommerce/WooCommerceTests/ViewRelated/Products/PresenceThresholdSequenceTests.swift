import XCTest
@testable import WooCommerce

final class PresenceThresholdSequenceTests: XCTestCase {

    func testExample() {
        let sequence = PresenceThresholdSequence<[String]>(threshold: 0.5, outOf: 10)
        XCTAssertEqual(sequence.append(value: ["hello"]), ["hello"])
        XCTAssertEqual(sequence.append(value: ["hello"]), nil)
        XCTAssertEqual(sequence.append(value: ["hey"]), ["hey"])
        XCTAssertEqual(sequence.append(value: ["hello"]), nil)
        XCTAssertEqual(sequence.append(value: ["hey"]), ["hey"])
        XCTAssertEqual(sequence.append(value: ["hey"]), nil)
        XCTAssertEqual(sequence.append(value: ["hello"]), nil)
    }

}
