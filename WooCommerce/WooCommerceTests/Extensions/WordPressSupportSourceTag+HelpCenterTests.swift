@testable import WordPressAuthenticator
@testable import WooCommerce

import XCTest

final class WordPressSupportSourceTag_HelpCenterTests: XCTestCase {

    func test_customHelpCenterURL_is_correct_for_loginSiteAddress() {
        let sourceTag = WordPressSupportSourceTag.loginSiteAddress
        XCTAssertEqual(sourceTag.customHelpCenterURL, WooConstants.URLs.helpCenterForEnterStoreAddress.asURL())
    }

    func test_customHelpCenterURL_is_nil_for_invalid_source_tag() {
        let sourceTag = WordPressSupportSourceTag(name: "a name", origin: "an origin")
        XCTAssertNil(sourceTag.customHelpCenterURL)
    }
}
