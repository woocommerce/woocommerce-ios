import XCTest
@testable import Networking

final class SettingsTests: XCTestCase {
    func test_wordpressApiBaseURL_when_wpComSandboxUsername_is_passed_then_it_returns_sandboxed_url() {
        let wpComSandboxUsername = "wpcomtester"
        let expectedResult = "https://\(wpComSandboxUsername).dev.dfw.wordpress.com/sandboxed-api/"

        XCTAssertEqual(Settings.wordpressApiBaseURL(wpComSandboxUsername: wpComSandboxUsername), expectedResult)
    }
}
