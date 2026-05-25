import XCTest
@testable import Networking
@testable import NetworkingCore

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

    /// Tests that flexible metadata decoding works with array format in a realistic context
    ///
    func test_flexible_metadata_decoding_array_format() throws {
        // Given - JSON with metadata as array in a product-like structure
        let jsonString = """
        {
            "id": 123,
            "name": "Test Product",
            "meta_data": [
                {
                    "id": 1001,
                    "key": "custom_field_1",
                    "value": "value1"
                },
                {
                    "id": 1002,
                    "key": "_internal_field",
                    "value": "internal_value"
                },
                {
                    "id": 1003,
                    "key": "custom_field_2",
                    "value": "value2"
                }
            ]
        }
        """

        struct TestProduct: Decodable {
            let id: Int
            let name: String
            let metadata: [MetaData]

            private enum CodingKeys: String, CodingKey {
                case id, name
                case metadata = "meta_data"
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.id = try container.decode(Int.self, forKey: .id)
                self.name = try container.decode(String.self, forKey: .name)

                // Flexible decoding logic using helper
                self.metadata = [MetaData].decodeFlexibly(from: container, forKey: .metadata)
            }
        }

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        // When
        let product = try decoder.decode(TestProduct.self, from: data)

        // Then
        XCTAssertEqual(product.metadata.count, 3) // All fields should be present
        XCTAssertEqual(product.metadata[0].metadataID, 1001)
        XCTAssertEqual(product.metadata[0].key, "custom_field_1")
        XCTAssertEqual(product.metadata[0].value.stringValue, "value1")
        XCTAssertEqual(product.metadata[1].metadataID, 1002)
        XCTAssertEqual(product.metadata[1].key, "_internal_field")
        XCTAssertEqual(product.metadata[1].value.stringValue, "internal_value")
        XCTAssertEqual(product.metadata[2].metadataID, 1003)
        XCTAssertEqual(product.metadata[2].key, "custom_field_2")
        XCTAssertEqual(product.metadata[2].value.stringValue, "value2")
    }

    /// Tests that flexible metadata decoding works with dictionary format in a realistic context
    ///
    func test_flexible_metadata_decoding_dictionary_format() throws {
        // Given - JSON with metadata as object keyed by index strings in a product-like structure
        let jsonString = """
        {
            "id": 456,
            "name": "Test Product 2",
            "meta_data": {
                "0": {
                    "id": 2001,
                    "key": "dict_field_1",
                    "value": "dict_value1"
                },
                "1": {
                    "id": 2002,
                    "key": "_internal_dict_field",
                    "value": "internal_dict_value"
                },
                "2": {
                    "id": 2003,
                    "key": "dict_field_2",
                    "value": "dict_value2"
                }
            }
        }
        """

        struct TestProduct: Decodable {
            let id: Int
            let name: String
            let metadata: [MetaData]

            private enum CodingKeys: String, CodingKey {
                case id, name
                case metadata = "meta_data"
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.id = try container.decode(Int.self, forKey: .id)
                self.name = try container.decode(String.self, forKey: .name)

                // Flexible decoding logic using helper
                self.metadata = [MetaData].decodeFlexibly(from: container, forKey: .metadata)
            }
        }

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        // When
        let product = try decoder.decode(TestProduct.self, from: data)

        // Then
        XCTAssertEqual(product.metadata.count, 3) // All fields should be present
        let fieldNames = Set(product.metadata.map { $0.key })
        XCTAssertTrue(fieldNames.contains("dict_field_1"))
        XCTAssertTrue(fieldNames.contains("dict_field_2"))
        XCTAssertTrue(fieldNames.contains("_internal_dict_field"))
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
