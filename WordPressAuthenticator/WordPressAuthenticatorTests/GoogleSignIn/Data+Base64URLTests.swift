@testable import WordPressAuthenticator
import XCTest

class DataBase64URLDecoding: XCTestCase {

    // MARK: - Decoding

    func testBase64URLDecoding() {
        XCTAssertEqual(
            Data(base64URLEncoded: "aGVsbG8gd29ybGQ"),
            "hello world".data(using: .utf8)
        )
    }

    func testBase64URLDecodingWithPadding() {
        XCTAssertEqual(
            Data(base64URLEncoded: "dGVzdA="),
            "test".data(using: .utf8)
        )
    }

    func testBase64URLDecodingWithDoublePadding() {
        XCTAssertEqual(
            Data(base64URLEncoded: "dGVzdA=="),
            "test".data(using: .utf8)
        )
    }

    func testBase64URLDecodingWithNonAlphaNumericCharacters() {
        XCTAssertEqual(
            Data(base64URLEncoded: "V2lsbCB0aGlzIHdvcmsgZm9yIGEgc3RyaW5nIHdpdGggbm9uLWFscGhhbnVtZXJpYyBjaGFyYWN0ZXJzPyE/JiU="),
            "Will this work for a string with non-alphanumeric characters?!?&%".data(using: .utf8)
        )
    }

    func testBase64URLDecodingWithEmptyString() {
        XCTAssertEqual(
            Data(base64URLEncoded: ""),
            Data()
        )
    }

    // MARK: - Encoding

    func testBase64URLEncoding() {
        XCTAssertEqual(
            "hello world".data(using: .utf8)!.base64URLEncodedString(),
            "aGVsbG8gd29ybGQ"
        )
        XCTAssertEqual(
            "Hello, /+ World!".data(using: .utf8)!.base64URLEncodedString(),
            "SGVsbG8sIC8rIFdvcmxkIQ"
        )
    }
}
