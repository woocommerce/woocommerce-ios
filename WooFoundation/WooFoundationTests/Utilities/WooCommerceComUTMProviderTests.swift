import Foundation
import TestKit
import XCTest

@testable import WooFoundation

final class WooCommerceComUTMProviderTests: XCTestCase {

    func test_query_string_has_all_passed_utm_parameters() throws {
        // Given
        let sut = WooCommerceComUTMProvider(campaign: "campaign_name",
                                            source: "source_name",
                                            content: "content_details",
                                            siteID: 12345)

        let urlString = "https://woocommerce.com"

        // When
        let url = try XCTUnwrap(sut.urlWithUtmParams(string: urlString))
        let query = try XCTUnwrap(url.query)

        // Then
        assertThat(query, contains: "utm_medium=woo_ios")
        assertThat(query, contains: "utm_campaign=campaign_name")
        assertThat(query, contains: "utm_source=source_name")
        assertThat(query, contains: "utm_content=content_details")
        assertThat(query, contains: "utm_term=12345")
    }

    func test_urlWithUtmParams_does_not_add_params_to_urls_other_than_woocommerce_com() throws {
        // Given
        let sut = WooCommerceComUTMProvider(campaign: "campaign_name",
                                            source: "source_name",
                                            content: nil,
                                            siteID: nil)

        let urlString = "https://wordpress.com"

        // When
        let url = try XCTUnwrap(sut.urlWithUtmParams(string: urlString))

        // Then
        XCTAssertNil(url.query)
    }
}
