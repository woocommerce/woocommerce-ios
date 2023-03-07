import Foundation
import TestKit
import XCTest

@testable import WooFoundation

final class UTMProviderProtocolExtensionTests: XCTestCase {

    func test_init_sets_utm_medium_to_woo_ios() {
        // Given, When
        let sut = MockUTMParameterProvider()

        // Then
        assertEqual("woo_ios", sut.parameters[.medium])
    }

    func test_query_string_has_all_passed_utm_parameters() throws {
        // Given
        let sut = MockUTMParameterProvider(parameters: [.medium: "woo_ios",
                                                        .campaign: "campaign_name",
                                                        .source: "source_name",
                                                        .content: "content_details",
                                                        .term: "12345"])

        let urlString = "https://example.com"

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
        let sut = MockUTMParameterProvider(parameters: [.medium: "woo_ios",
                                                        .campaign: "campaign_name",
                                                        .source: "source_name",
                                                        .content: nil,
                                                        .term: nil])

        let urlString = "https://example.com"

        // When
        let url = try XCTUnwrap(sut.urlWithUtmParams(string: urlString))
        let query = try XCTUnwrap(url.query)

        // Then
        XCTAssertFalse(query.contains("utm_content"))
        XCTAssertFalse(query.contains("utm_term"))
    }

    func test_query_string_overwrites_using_passed_in_utm_parameters() throws {
        // Given
        let sut = MockUTMParameterProvider(parameters: [.medium: "woo_ios",
                                                        .campaign: "campaign_name",
                                                        .source: "source_name",
                                                        .content: nil,
                                                        .term: nil])

        let urlString = "https://example.com?utm_campaign=existing_campaign"

        // When
        let url = try XCTUnwrap(sut.urlWithUtmParams(string: urlString))
        let query = try XCTUnwrap(url.query)

        // Then
        assertThat(query, contains: "utm_campaign=campaign_name")
        XCTAssertFalse(query.contains("utm_campaign=existing_campaign"))
    }

    func test_query_string_preserves_existing_when_nil_is_passed_in_utm_parameters() throws {
        // Given
        let sut = MockUTMParameterProvider(parameters: [.medium: "woo_ios",
                                                        .campaign: "campaign_name",
                                                        .source: "source_name",
                                                        .content: nil,
                                                        .term: nil])

        let urlString = "https://example.com?utm_term=keyword"

        // When
        let url = try XCTUnwrap(sut.urlWithUtmParams(string: urlString))
        let query = try XCTUnwrap(url.query)

        // Then
        assertThat(query, contains: "utm_term=keyword")
    }

    func test_urlWithUtmParams_does_not_add_params_to_urls_not_in_limitToHosts_when_set() throws {
        // Given
        var sut = MockUTMParameterProvider(parameters: [.medium: "woo_ios",
                                                        .campaign: "campaign_name",
                                                        .source: "source_name",
                                                        .content: nil,
                                                        .term: nil])
        sut.limitToHosts = ["wordpress.com", "woocommerce.com"]

        let urlString = "https://example.com"

        // When
        let url = try XCTUnwrap(sut.urlWithUtmParams(string: urlString))

        // Then
        XCTAssertNil(url.query)
        assertEqual(URL(string: "https://example.com"), url)
    }

    func test_urlWithUtmParams_does_not_add_params_to_urls_not_in_limitToHosts_even_when_empty() throws {
        // Given
        var sut = MockUTMParameterProvider(parameters: [.medium: "woo_ios",
                                                        .campaign: "campaign_name",
                                                        .source: "source_name",
                                                        .content: nil,
                                                        .term: nil])
        sut.limitToHosts = []

        let urlString = "https://example.com"

        // When
        let url = try XCTUnwrap(sut.urlWithUtmParams(string: urlString))

        // Then
        XCTAssertNil(url.query)
        assertEqual(URL(string: "https://example.com"), url)
    }

    func test_urlWithUtmParams_adds_params_to_urls_in_limitToHosts() throws {
        // Given
        var sut = MockUTMParameterProvider(parameters: [.medium: "woo_ios",
                                                        .campaign: "campaign_name",
                                                        .source: "source_name",
                                                        .content: nil,
                                                        .term: nil])
        sut.limitToHosts = ["woocommerce.com", "example.com"]

        let urlString = "https://example.com"

        // When
        let url = try XCTUnwrap(sut.urlWithUtmParams(string: urlString))
        let query = try XCTUnwrap(url.query)

        // Then
        assertThat(query, contains: "utm_campaign=campaign_name")
    }

}
