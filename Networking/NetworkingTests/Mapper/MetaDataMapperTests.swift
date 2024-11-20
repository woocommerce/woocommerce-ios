import XCTest
@testable import Networking

final class MetaDataMapperTests: XCTestCase {

    /// Tests that MetaData is correctly mapped from a meta_data response.
    ///
    /// - Throws: An error if the mapping fails.
    func test_it_maps_MetaData_correctly_from_meta_data_response() throws {
        // Given
        let data = try retrieveMetaDataResponse()
        let mapper = MetaDataMapper()

        // When
        let metadata = try mapper.map(response: data)

        // Then
        XCTAssertEqual(metadata.count, 7)

        XCTAssertEqual(metadata[0], MetaData(metadataID: 1, key: "text_field", value: "Lorem ipsum"))
        XCTAssertEqual(metadata[1], MetaData(metadataID: 2, key: "json_field", value: "{\"key\":\"value\"}"))
        XCTAssertEqual(metadata[2], MetaData(metadataID: 3, key: "json_array_field", value: "[{\"key\":\"value\"}]"))
        XCTAssertEqual(metadata[3], MetaData(metadataID: 4, key: "json_field_wrapped", value: "\"{\"key\":\"value\"}\""))
        XCTAssertEqual(metadata[4], MetaData(metadataID: 5, key: "boolean_field", value: "true"))
        XCTAssertEqual(metadata[5], MetaData(metadataID: 6, key: "number_field", value: "42"))
        XCTAssertEqual(metadata[6], MetaData(metadataID: 7, key: "empty_field", value: ""))
    }

    /// Tests that MetaData is correctly mapped from a meta_data nested in data response.
    ///
    /// - Throws: An error if the mapping fails.
    func test_it_maps_MetaData_correctly_from_meta_data_nested_in_data_response() throws {
        // Given
        let data = try retrieveMetaDataResponseNestedInData()
        let mapper = MetaDataMapper()

        // When
        let metadata = try mapper.map(response: data)

        // Then
        XCTAssertEqual(metadata.count, 7)

        XCTAssertEqual(metadata[0], MetaData(metadataID: 1, key: "text_field", value: "Lorem ipsum"))
        XCTAssertEqual(metadata[1], MetaData(metadataID: 2, key: "json_field", value: "{\"key\":\"value\"}"))
        XCTAssertEqual(metadata[2], MetaData(metadataID: 3, key: "json_array_field", value: "[{\"key\":\"value\"}]"))
        XCTAssertEqual(metadata[3], MetaData(metadataID: 4, key: "json_field_wrapped", value: "\"{\"key\":\"value\"}\""))
        XCTAssertEqual(metadata[4], MetaData(metadataID: 5, key: "boolean_field", value: "true"))
        XCTAssertEqual(metadata[5], MetaData(metadataID: 6, key: "number_field", value: "42"))
        XCTAssertEqual(metadata[6], MetaData(metadataID: 7, key: "empty_field", value: ""))
    }
}

// MARK: - Test Helpers
///
private extension MetaDataMapperTests {
    func retrieveMetaDataResponse() throws -> Data {
        guard let response = Loader.contentsOf("meta-data-products-and-orders") else {
            throw FileNotFoundError()
        }

        return response
    }

    func retrieveMetaDataResponseNestedInData() throws -> Data {
        guard let response = Loader.contentsOf("meta-data-products-and-orders_nested_in_data") else {
            throw FileNotFoundError()
        }

        return response
    }

    struct FileNotFoundError: Error {}
}
