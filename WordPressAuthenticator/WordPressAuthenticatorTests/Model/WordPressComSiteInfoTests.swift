import XCTest
@testable import WordPressAuthenticator

final class WordPressComSiteInfoTests: XCTestCase {
    private var subject: WordPressComSiteInfo!

    override func setUp() {
        subject = WordPressComSiteInfo(remote: mock())
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    func testJetpackActiveMatchesExpectation() {
        XCTAssertTrue(subject.isJetpackActive)
    }

    func testHasJetpackMatchesExpectation() {
        XCTAssertTrue(subject.hasJetpack)
    }

    func testJetpackConnectedMatchesExpectation() {
        XCTAssertTrue(subject.isJetpackConnected)
    }

    func testWPComMatchesExpectation() {
        XCTAssertFalse(subject.isWPCom)
    }

    func testWPMatchesExpectation() {
        XCTAssertTrue(subject.isWP)
    }
}

private extension WordPressComSiteInfoTests {
    func mock() -> [AnyHashable: Any] {
        return [
            "isJetpackActive": "1",
            "jetpackVersion": "0",
            "isWordPressDotCom": "0",
            "urlAfterRedirects": "https://somewhere.com",
            "hasJetpack": "1",
            "isWordPress": "1",
            "isJetpackConnected": "1"
        ] as [AnyHashable: Any]
    }
}
