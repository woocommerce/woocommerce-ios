@testable import WordPressAuthenticator
import XCTest

class GoogleClientIdTests: XCTestCase {

    func testFailsInitIfNotAValidFormat() {
       XCTAssertNil(GoogleClientId(string: "invalid"))
    }

    func testDoesNotFailInitIfValidFormat() {
        XCTAssertNotNil(GoogleClientId(string: "com.something.something"))
        XCTAssertNotNil(GoogleClientId(string: "a.b.c"))
    }
}
