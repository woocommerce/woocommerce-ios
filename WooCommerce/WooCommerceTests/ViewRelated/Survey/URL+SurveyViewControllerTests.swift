import Foundation
import XCTest

@testable import WooCommerce

/// Test cases for `URL extension at SurveyViewController`.

final class URL_SurveyViewControllerTests: XCTestCase {

    func test_tagging_platform_appends_the_correct_tag_data() throws {
        let expectedURL = "https://testurl.com?woo-mobile-platform=test"

        let actualURL = URL(string: "https://testurl.com")?.tagPlatform("test").absoluteString

        XCTAssertEqual(expectedURL, actualURL)
    }

    func test_tagging_app_version_appends_the_correct_tag_data() throws {
        let expectedURL = "https://testurl.com?app-version=1.2.3"

        let actualURL = URL(string: "https://testurl.com")?.tagAppVersion("1.2.3").absoluteString

        XCTAssertEqual(expectedURL, actualURL)
    }

    func test_tagging_site_info_appends_the_correct_tag_data() throws {
        let siteID: Int64 = 123
        let testURL = "https://example.com"
        let storeUUID = "8363cd24-2501-463f-b21b-649315a0d507"

        let expectedURL = "https://testurl.com?site-id=\(siteID)&store-id=\(storeUUID)&store-url=\(testURL)"

        let actualURL = URL(string: "https://testurl.com")?.tagSiteInfo(siteID: siteID,
                                                                        storeUUID: storeUUID,
                                                                        storeURL: testURL).absoluteString

        XCTAssertEqual(expectedURL, actualURL)
    }
}
