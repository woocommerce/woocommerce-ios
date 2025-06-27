import XCTest
@testable import Networking
@testable import NetworkingCore

final class ProductOrVariationIDCodableTests: XCTestCase {

    func test_product_encodes_and_decodes_correctly() throws {
        // Given
        let productID = ProductOrVariationID.product(id: 999)

        // When
        let data = try JSONEncoder().encode(productID)
        let decodedProductID = try JSONDecoder().decode(ProductOrVariationID.self, from: data)

        // Then
        XCTAssertEqual(productID, decodedProductID)
    }

    func test_variation_encodes_and_decodes_correctly() throws {
        // Given
        let variationID = ProductOrVariationID.variation(productID: 888, variationID: 777)

        // When
        let data = try JSONEncoder().encode(variationID)
        let decodedVariationID = try JSONDecoder().decode(ProductOrVariationID.self, from: data)

        // Then
        XCTAssertEqual(variationID, decodedVariationID)
    }

    func test_decoding_unknown_type_throws_error() throws {
        // Given
        let jsonData = """
        {
            "type": "unknownType",
            "id": 1234
        }
        """.data(using: .utf8)!

        // Then
        XCTAssertThrowsError(try JSONDecoder().decode(ProductOrVariationID.self, from: jsonData)) { error in
            if case let DecodingError.dataCorrupted(context) = error {
                XCTAssertTrue(context.debugDescription.contains("unknownType"))
            } else {
                XCTFail("Expected dataCorrupted error, but got: \(error)")
            }
        }
    }

    func test_decoding_missing_id_for_product_throws_error() throws {
        // Given
        let jsonData = """
        {
            "type": "product"
        }
        """.data(using: .utf8)!

        // Then
        XCTAssertThrowsError(try JSONDecoder().decode(ProductOrVariationID.self, from: jsonData)) { error in
            if case let DecodingError.keyNotFound(key, _) = error {
                XCTAssertEqual(key.stringValue, "id")
            } else {
                XCTFail("Expected keyNotFound error for 'id', but got: \(error)")
            }
        }
    }

    func test_decoding_missing_variationID_throws_error() throws {
        // Given
        let jsonData = """
        {
            "type": "variation",
            "productID": 888
        }
        """.data(using: .utf8)!

        // Then
        XCTAssertThrowsError(try JSONDecoder().decode(ProductOrVariationID.self, from: jsonData)) { error in
            if case let DecodingError.keyNotFound(key, _) = error {
                XCTAssertEqual(key.stringValue, "variationID")
            } else {
                XCTFail("Expected keyNotFound error for 'variationID', but got: \(error)")
            }
        }
    }

    func test_id_property_returns_correct_value_for_product() {
        // Given
        let productID = ProductOrVariationID.product(id: 123)

        // Then
        XCTAssertEqual(productID.id, 123)
    }

    func test_id_property_returns_correct_value_for_variation() {
        // Given
        let variationID = ProductOrVariationID.variation(productID: 456, variationID: 789)

        // Then
        XCTAssertEqual(variationID.id, 789)
    }
}
