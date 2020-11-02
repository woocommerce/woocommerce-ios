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

    func test_tagging_product_milestone_appends_the_correct_tag_data() throws {
        let expectedURL = "https://testurl.com?product-milestone=test"

        let actualURL = URL(string: "https://testurl.com")?.tagProductMilestone("test").absoluteString

        XCTAssertEqual(expectedURL, actualURL)
    }

    func test_tagging_platform_and_tagging_product_milestone_does_stack() throws {
            let actualURL =
                URL(string: "https://testurl.com")?
                .tagPlatform("ios")
                .tagProductMilestone("123")
                .absoluteString

            let expectedURL = "https://testurl.com?woo-mobile-platform=ios&product-milestone=123"

            XCTAssertEqual(expectedURL, actualURL)
    }

    func test_tagging_platform_and_tagging_product_milestone_does_stack_in_order() throws {
        let actualURL =
            URL(string: "https://testurl.com")?
            .tagProductMilestone("123")
            .tagPlatform("ios")
            .absoluteString

        let expectedURL = "https://testurl.com?product-milestone=123&woo-mobile-platform=ios"

        XCTAssertEqual(expectedURL, actualURL)
    }
}
