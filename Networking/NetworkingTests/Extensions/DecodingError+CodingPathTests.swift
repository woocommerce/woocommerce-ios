import XCTest

final class DecodingError_CodingPathTests: XCTestCase {
    private let mockDebugDescription = "Mock decoding error"

    func test_debugPath_creates_expected_string_from_codingPath() {
        // Given
        let mockCodingPath = [MockCodingKeys.items, MockCodingKeys.index, MockCodingKeys.name]
        let error = DecodingError.dataCorrupted(.init(codingPath: mockCodingPath, debugDescription: mockDebugDescription))

        // Then
        assertEqual("items.name", error.debugPath)
    }

    func test_dataCorrupted_decoding_error_has_expected_properties() {
        // Given
        let error = DecodingError.dataCorrupted(.init(codingPath: [MockCodingKeys.name], debugDescription: mockDebugDescription))

        // Then
        assertEqual("name", error.debugPath)
        assertEqual(mockDebugDescription, error.debugDescription)
    }

    func test_keyNotFound_decoding_error_has_expected_properties() {
        // Given
        let error = DecodingError.keyNotFound(MockCodingKeys.name, .init(codingPath: [MockCodingKeys.name], debugDescription: mockDebugDescription))

        // Then
        assertEqual("name", error.debugPath)
        assertEqual(mockDebugDescription, error.debugDescription)
    }

    func test_typeMismatch_decoding_error_has_expected_properties() {
        // Given
        let error = DecodingError.typeMismatch(String.self, .init(codingPath: [MockCodingKeys.name], debugDescription: mockDebugDescription))

        // Then
        assertEqual("name", error.debugPath)
        assertEqual(mockDebugDescription, error.debugDescription)
    }

    func test_valueNotFound_decoding_error_has_expected_properties() {
        // Given
        let error = DecodingError.valueNotFound(String.self, .init(codingPath: [MockCodingKeys.name], debugDescription: mockDebugDescription))

        // Then
        assertEqual("name", error.debugPath)
        assertEqual(mockDebugDescription, error.debugDescription)
    }

}

private extension DecodingError_CodingPathTests {
    enum MockCodingKeys: String, CodingKey {
        case items
        case index = "Index 0"
        case name
    }
}
