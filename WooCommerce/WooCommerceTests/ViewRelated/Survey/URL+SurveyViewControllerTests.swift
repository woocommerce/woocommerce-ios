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

    func test_tagging_shipping_labels_milestone_appends_the_correct_tag_data() throws {
        let expectedURL = "https://testurl.com?shipping_label_milestone=test"

        let actualURL = URL(string: "https://testurl.com")?.tagShippingLabelsMilestone("test").absoluteString

        XCTAssertEqual(expectedURL, actualURL)
    }

    func test_tagging_platform_and_tagging_shipping_labels_milestone_does_stack_in_order() throws {
        let actualURL =
            URL(string: "https://testurl.com")?
            .tagShippingLabelsMilestone("123")
            .tagPlatform("ios")
            .absoluteString

        let expectedURL = "https://testurl.com?shipping_label_milestone=123&woo-mobile-platform=ios"

        XCTAssertEqual(expectedURL, actualURL)
    }
}
