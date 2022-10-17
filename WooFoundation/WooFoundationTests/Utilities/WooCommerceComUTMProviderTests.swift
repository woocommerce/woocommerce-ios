import Foundation
import TestKit
import XCTest

@testable import WooFoundation

final class WooCommerceComUTMProviderTests: XCTestCase {

    func test_init_sets_utm_medium_to_woo_ios() {
        // Given, When
        let sut = WooCommerceComUTMProvider(campaign: "", source: "", content: nil, siteID: nil)

        // Then
        assertEqual("woo_ios", sut.parameters[.medium])
    }

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

    func test_query_string_excludes_nils_passed_in_utm_parameters() throws {
        // Given
        let sut = WooCommerceComUTMProvider(campaign: "campaign_name",
                                            source: "source_name",
                                            content: nil,
                                            siteID: nil)

        let urlString = "https://woocommerce.com"

        // When
        let url = try XCTUnwrap(sut.urlWithUtmParams(string: urlString))
        let query = try XCTUnwrap(url.query)

        // Then
        XCTAssertFalse(query.contains("utm_content"))
        XCTAssertFalse(query.contains("utm_term"))
    }

    func test_query_string_overwrites_using_passed_in_utm_parameters() throws {
        // Given
        let sut = WooCommerceComUTMProvider(campaign: "campaign_name",
                                            source: "source_name",
                                            content: nil,
                                            siteID: nil)

        let urlString = "https://woocommerce.com?utm_campaign=existing_campaign"

        // When
        let url = try XCTUnwrap(sut.urlWithUtmParams(string: urlString))
        let query = try XCTUnwrap(url.query)

        // Then
        assertThat(query, contains: "utm_campaign=campaign_name")
        XCTAssertFalse(query.contains("utm_campaign=existing_campaign"))
    }

    func test_query_string_preserves_existing_when_nil_is_passed_in_utm_parameters() throws {
        // Given
        let sut = WooCommerceComUTMProvider(campaign: "campaign_name",
                                            source: "source_name",
                                            content: nil,
                                            siteID: nil)

        let urlString = "https://woocommerce.com?utm_term=keyword"

        // When
        let url = try XCTUnwrap(sut.urlWithUtmParams(string: urlString))
        let query = try XCTUnwrap(url.query)

        // Then
        assertThat(query, contains: "utm_term=keyword")
    }

}
