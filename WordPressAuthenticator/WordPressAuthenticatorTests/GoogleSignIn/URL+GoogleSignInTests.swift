@testable import WordPressAuthenticator
import XCTest

class URLGoogleSignInTests: XCTestCase {

    func testGoogleSignInAuthURL() throws {
        let url = try URL.googleSignInAuthURL()

        assert(url, matchesBaseURL: "https://accounts.google.com/o/oauth2/v2/auth")
        assertQueryItems(for: url, includeItemNamed: "response_type", withValue: "code")
        // TODO: need to check more parameters
    }
}

func assert(
    _ actual: URL,
    matchesBaseURL baseURLString: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    guard var components = URLComponents(url: actual, resolvingAgainstBaseURL: false) else {
        return XCTFail(
            "Could not created `URLComponents` from given `URL` \(actual).",
            file: file,
            line: line
        )
    }

    components.query = .none

    guard let baseURL = components.url else {
        return XCTFail(
            "Could not extract `URL` from `URLComponents` created from \(actual).",
            file: file,
            line: line
        )
    }

    XCTAssertEqual(baseURL.absoluteString, baseURLString, file: file, line: line)
}

func assertQueryItems(
    for url: URL,
    includeItemNamed name: String,
    withValue value: String?,
    file: StaticString = #file,
    line: UInt = #line
) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        return XCTFail(
            "Could not created `URLComponents` from given `URL` \(url).",
            file: file,
            line: line
        )
    }

    guard let queryItems = components.queryItems else {
        XCTFail("URL \(url) has no query items", file: file, line: line)
        return
    }

    XCTAssertTrue(
        queryItems.contains(where: { $0.name == name && $0.value == value }),
        "Could not find query item with name '\(name)' and value '\(value ?? "nil")'. Query items found: \(queryItems.map { "'name: \($0.name), value: \($0.value ?? "nil")'" }.joined(separator: ", "))",
        file: file,
        line: line
    )
}
