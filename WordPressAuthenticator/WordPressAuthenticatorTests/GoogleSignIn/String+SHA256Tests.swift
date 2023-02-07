@testable import WordPressAuthenticator
import XCTest

class StringSHA256Tests: XCTestCase {

    func testSHA256Hasing() {
        XCTAssertEqual(
            "foo".sha256Hashed,
            "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae"
        )
        XCTAssertEqual(
            "bar".sha256Hashed,
             "fcde2b2edba56bf408601fb721fe9b5c338d10ee429ea04fae5511b68fbf8fb9"
        )
        XCTAssertEqual(
            "abcABC-=/?".sha256Hashed,
             "e8552e6ddda2103b18158c28ecd834b1772c72794011547c9ef6d8fcb3419a23"
        )
    }
}
