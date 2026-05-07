import Foundation
import Testing
@testable import WooCommerce

@Suite(.timeLimit(.minutes(1)))
struct AIToolResponseMapperTests {

    @Test
    func test_map_when_jetpack_envelope_then_returns_inner_data() throws {
        // Given
        let raw = #"{"data":[{"id":1},{"id":2}]}"#
        let input = Data(raw.utf8)

        // When
        let unwrapped = try AIToolResponseMapper().map(response: input)

        // Then
        let parsed = try #require(try JSONSerialization.jsonObject(with: unwrapped) as? [[String: Any]])
        #expect(parsed.count == 2)
        #expect(parsed.first?["id"] as? Int == 1)
    }

    @Test
    func test_map_when_naked_payload_then_returned_unchanged() throws {
        // Given
        let raw = #"[{"id":1}]"#
        let input = Data(raw.utf8)

        // When
        let unwrapped = try AIToolResponseMapper().map(response: input)

        // Then
        #expect(unwrapped == input)
    }

    @Test
    func test_map_when_wp_error_envelope_with_code_field_then_returned_unchanged() throws {
        // Given
        let raw = #"{"code":"rest_no_route","message":"No route was found","data":{"status":404}}"#
        let input = Data(raw.utf8)

        // When
        let unwrapped = try AIToolResponseMapper().map(response: input)

        // Then
        #expect(unwrapped == input)
    }

    @Test
    func test_map_when_empty_then_returned_unchanged() throws {
        // Given
        let input = Data()

        // When
        let unwrapped = try AIToolResponseMapper().map(response: input)

        // Then
        #expect(unwrapped == input)
    }

    @Test
    func test_map_when_unparseable_then_returned_unchanged() throws {
        // Given
        let input = Data("not json".utf8)

        // When
        let unwrapped = try AIToolResponseMapper().map(response: input)

        // Then
        #expect(unwrapped == input)
    }

    @Test
    func test_map_when_wp_error_envelope_has_numeric_code_then_returned_unchanged() throws {
        // Given
        let raw = #"{"code":42,"message":"Bad Request","data":{"status":400}}"#
        let input = Data(raw.utf8)

        // When
        let unwrapped = try AIToolResponseMapper().map(response: input)

        // Then
        #expect(unwrapped == input)
    }

    @Test
    func test_map_when_jetpack_envelope_has_sibling_metadata_then_strips_to_inner_only() throws {
        // Given
        let raw = #"{"data":{"id":42,"title":"Hat"},"path":"/wc/v3/products/42","status":200}"#
        let input = Data(raw.utf8)

        // When
        let unwrapped = try AIToolResponseMapper().map(response: input)

        // Then
        let parsed = try #require(try JSONSerialization.jsonObject(with: unwrapped) as? [String: Any])
        #expect(parsed["id"] as? Int == 42)
        #expect(parsed["title"] as? String == "Hat")
        #expect(parsed["path"] == nil)
        #expect(parsed["status"] == nil)
    }

    @Test
    func test_map_when_jetpack_envelope_has_empty_array_inner_then_returns_empty_array() throws {
        // Given
        let raw = #"{"data":[]}"#
        let input = Data(raw.utf8)

        // When
        let unwrapped = try AIToolResponseMapper().map(response: input)

        // Then
        let parsed = try #require(try JSONSerialization.jsonObject(with: unwrapped) as? [Any])
        #expect(parsed.isEmpty)
    }

    @Test
    func test_map_when_jetpack_envelope_has_null_inner_then_returns_json_null() throws {
        // Given
        let raw = #"{"data":null}"#
        let input = Data(raw.utf8)

        // When
        let unwrapped = try AIToolResponseMapper().map(response: input)

        // Then
        #expect(String(data: unwrapped, encoding: .utf8) == "null")
    }
}
