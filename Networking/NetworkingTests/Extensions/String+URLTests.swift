import XCTest
@testable import Networking

final class String_URLTests: XCTestCase {
    func test_prefix_slash() {
        XCTAssertEqual("/test".trimSlashes(), "test")
    }

    func test_suffix_slash() {
        XCTAssertEqual("test/".trimSlashes(), "test")
    }

    func test_prefix_and_suffix_slashes() {
        XCTAssertEqual("/test/".trimSlashes(), "test")
    }

    func test_prefix_suffix_and_extra_slashes() {
        XCTAssertEqual("/te/st/".trimSlashes(), "te/st")
    }
}
