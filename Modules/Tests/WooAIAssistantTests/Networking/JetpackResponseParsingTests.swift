import Foundation
import Testing
@testable import WooAIAssistant

struct JetpackResponseParsingTests {

    // MARK: - unwrapJetpackEnvelope

    @Test
    func test_unwrapJetpackEnvelope_when_jetpack_wrapped_then_returns_inner_data() throws {
        // Given
        let raw = #"{"data":[{"id":1},{"id":2}]}"#
        let input = Data(raw.utf8)

        // When
        let unwrapped = JetpackResponseParsing.unwrapJetpackEnvelope(input)

        // Then
        let parsed = try #require(try JSONSerialization.jsonObject(with: unwrapped) as? [[String: Any]])
        #expect(parsed.count == 2)
        #expect(parsed.first?["id"] as? Int == 1)
    }

    @Test
    func test_unwrapJetpackEnvelope_when_naked_payload_then_returned_unchanged() {
        // Given
        let raw = #"[{"id":1}]"#
        let input = Data(raw.utf8)

        // When
        let unwrapped = JetpackResponseParsing.unwrapJetpackEnvelope(input)

        // Then
        #expect(unwrapped == input)
    }

    @Test
    func test_unwrapJetpackEnvelope_when_wp_error_envelope_with_code_field_then_returned_unchanged() {
        // Given - WP error envelope ALSO has a `data` key but its inner value
        // is error metadata, not a row. The presence of a non-empty `code`
        // sibling is the signal to leave the bytes alone so the higher layer
        // can surface the error.
        let raw = #"{"code":"rest_no_route","message":"No route was found","data":{"status":404}}"#
        let input = Data(raw.utf8)

        // When
        let unwrapped = JetpackResponseParsing.unwrapJetpackEnvelope(input)

        // Then
        #expect(unwrapped == input)
    }

    @Test
    func test_unwrapJetpackEnvelope_when_empty_then_returned_unchanged() {
        // Given
        let input = Data()

        // When
        let unwrapped = JetpackResponseParsing.unwrapJetpackEnvelope(input)

        // Then
        #expect(unwrapped == input)
    }

    @Test
    func test_unwrapJetpackEnvelope_when_unparseable_then_returned_unchanged() {
        // Given
        let input = Data("not json".utf8)

        // When
        let unwrapped = JetpackResponseParsing.unwrapJetpackEnvelope(input)

        // Then
        #expect(unwrapped == input)
    }

    // MARK: - splitAPIVersion

    @Test
    func test_splitAPIVersion_when_wc_v3_path_then_mark3() {
        // Given
        let path = "wc/v3/orders"

        // When
        let result = JetpackResponseParsing.splitAPIVersion(from: path)

        // Then
        #expect(result.apiVersion == .mark3)
        #expect(result.subpath == "orders")
    }

    @Test
    func test_splitAPIVersion_when_wc_analytics_path_then_wcAnalytics() {
        // Given
        let path = "wc-analytics/reports/orders"

        // When
        let result = JetpackResponseParsing.splitAPIVersion(from: path)

        // Then
        #expect(result.apiVersion == .wcAnalytics)
        #expect(result.subpath == "reports/orders")
    }

    @Test
    func test_splitAPIVersion_when_leading_slash_then_trimmed() {
        // Given
        let path = "/wc/v3/products"

        // When
        let result = JetpackResponseParsing.splitAPIVersion(from: path)

        // Then
        #expect(result.apiVersion == .mark3)
        #expect(result.subpath == "products")
    }

    @Test
    func test_splitAPIVersion_when_unknown_prefix_then_falls_back_to_mark3_with_full_path() {
        // Given - typo / unknown prefix should reach a valid namespace that
        // 404s loudly rather than silently succeeding.
        let path = "made_up_ns/orders"

        // When
        let result = JetpackResponseParsing.splitAPIVersion(from: path)

        // Then
        #expect(result.apiVersion == .mark3)
        #expect(result.subpath == "made_up_ns/orders")
    }

    @Test
    func test_splitAPIVersion_when_wc_v4_path_then_mark4() {
        // Given
        let path = "wc/v4/customers"

        // When
        let result = JetpackResponseParsing.splitAPIVersion(from: path)

        // Then
        #expect(result.apiVersion == .mark4)
        #expect(result.subpath == "customers")
    }
}
