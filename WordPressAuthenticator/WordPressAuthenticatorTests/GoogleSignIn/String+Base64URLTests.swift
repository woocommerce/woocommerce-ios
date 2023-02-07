@testable import WordPressAuthenticator
import XCTest

class StringBase64URLTests: XCTestCase {

    func testBase64URLEncoding() {
        XCTAssertEqual("hello".base64URLEncoded, "aGVsbG8=")
        XCTAssertEqual("hello123".base64URLEncoded, "aGVsbG8xMjM=")
        XCTAssertEqual("hello!@#$%".base64URLEncoded, "aGVsbG8hQCMkJQ==")
        XCTAssertEqual("hello世界".base64URLEncoded, "aGVsbG_kuJbnlYw=")
        XCTAssertEqual("".base64URLEncoded, "")
        XCTAssertEqual(
            "a very long string with a maximum length allowed by the implementation".base64URLEncoded,
            "YSB2ZXJ5IGxvbmcgc3RyaW5nIHdpdGggYSBtYXhpbXVtIGxlbmd0aCBhbGxvd2VkIGJ5IHRoZSBpbXBsZW1lbnRhdGlvbg=="
        )
    }
}
