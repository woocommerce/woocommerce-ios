import Foundation
import Testing
@testable import NetworkingCore

// Mappers pick their decoding shape from this check: a wrong answer fails every response of that shape.
struct MapperDataEnvelopeTests {
    private struct DummyMapper: Mapper {
        func map(response: Data) throws -> Void {}
    }

    @Test func test_hasDataEnvelope_when_root_data_key_holds_a_value_then_returns_true() {
        // Given
        let response = Data(#"{"data": [{"id": 1}]}"#.utf8)

        // When
        let result = DummyMapper().hasDataEnvelope(in: response)

        // Then
        #expect(result)
    }

    @Test func test_hasDataEnvelope_when_root_data_key_is_null_then_returns_true() {
        // Given
        let response = Data(#"{"data": null}"#.utf8)

        // When
        let result = DummyMapper().hasDataEnvelope(in: response)

        // Then
        #expect(result)
    }

    @Test func test_hasDataEnvelope_when_root_is_an_array_then_returns_false() {
        // Given
        let response = Data(#"[{"data": 1}]"#.utf8)

        // When
        let result = DummyMapper().hasDataEnvelope(in: response)

        // Then
        #expect(!result)
    }

    @Test(arguments: [#""data""#, "1"])
    func test_hasDataEnvelope_when_root_is_a_string_or_number_then_returns_false(json: String) {
        // Given
        let response = Data(json.utf8)

        // When
        let result = DummyMapper().hasDataEnvelope(in: response)

        // Then
        #expect(!result)
    }

    @Test func test_hasDataEnvelope_when_data_key_is_only_nested_then_returns_false() {
        // Given
        let response = Data(#"{"items": {"data": 1}}"#.utf8)

        // When
        let result = DummyMapper().hasDataEnvelope(in: response)

        // Then
        #expect(!result)
    }
}
