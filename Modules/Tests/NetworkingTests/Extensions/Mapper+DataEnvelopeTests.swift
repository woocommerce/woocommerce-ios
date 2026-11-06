import Foundation
import Testing
@testable import NetworkingCore

// Mappers pick their decoding shape from this check: a wrong answer fails every response of that shape.
struct MapperDataEnvelopeTests {
    private struct DummyMapper: Mapper {
        func map(response: Data) throws -> Void {}
    }

    @Test func test_hasDataEnvelope_when_root_data_key_is_null_then_returns_true() {
        // Given
        let response = Data(#"{"data": null}"#.utf8)

        // When
        let result = DummyMapper().hasDataEnvelope(in: response)

        // Then
        #expect(result)
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
