import XCTest
@testable import WooCommerce
@testable import WordPressAuthenticator

final class WordPressComSiteInfoWooTests: XCTestCase {
    func test_is_valid_when_jetpack_is_active_and_connected() {
        let infoSite = WordPressComSiteInfo(remote: hasJetpack())

        XCTAssertTrue(infoSite.hasValidJetpack)
    }

    func test_is_not_valid_when_site_does_not_have_jetpack() {
        let infoSite = WordPressComSiteInfo(remote: doesNotHaveJetpack())

        XCTAssertFalse(infoSite.hasValidJetpack)
    }

    func test_is_not_valid_when_site_has_jetpack_installed_but_not_active() {
        let infoSite = WordPressComSiteInfo(remote: hasJetpackInactive())

        XCTAssertFalse(infoSite.hasValidJetpack)
    }

    func test_is_not_valid_when_site_has_jetpack_installed_but_not_connected() {
        let infoSite = WordPressComSiteInfo(remote: hasJetpackNotConnected())

        XCTAssertFalse(infoSite.hasValidJetpack)
    }
}


private extension WordPressComSiteInfoWooTests {
    func hasJetpack() -> [AnyHashable: Any] {
        return [
            "isJetpackActive": true,
            "jetpackVersion": false,
            "isWordPressDotCom": false,
            "urlAfterRedirects": "https://somewhere.com",
            "hasJetpack": true,
            "isWordPress": true,
            "isJetpackConnected": true
        ] as [AnyHashable: Any]
    }

    func doesNotHaveJetpack() -> [AnyHashable: Any] {
        return [
            "isJetpackActive": true,
            "jetpackVersion": false,
            "isWordPressDotCom": false,
            "urlAfterRedirects": "https://somewhere.com",
            "hasJetpack": false,
            "isWordPress": true,
            "isJetpackConnected": true
        ] as [AnyHashable: Any]
    }

    func hasJetpackInactive() -> [AnyHashable: Any] {
        return [
            "isJetpackActive": false,
            "jetpackVersion": false,
            "isWordPressDotCom": false,
            "urlAfterRedirects": "https://somewhere.com",
            "hasJetpack": true,
            "isWordPress": true,
            "isJetpackConnected": true
        ] as [AnyHashable: Any]
    }

    func hasJetpackNotConnected() -> [AnyHashable: Any] {
        return [
            "isJetpackActive": true,
            "jetpackVersion": false,
            "isWordPressDotCom": false,
            "urlAfterRedirects": "https://somewhere.com",
            "hasJetpack": true,
            "isWordPress": true,
            "isJetpackConnected": false
        ] as [AnyHashable: Any]
    }
}
