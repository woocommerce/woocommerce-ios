import Foundation
import XCTest
@testable import Networking

/// Check MetaData encoding to Dictionary
///
class MetaDataEncoderTests: XCTestCase {
    func test_encode_metadataString_to_dictionary() throws {
        // Given
        let metadata = MetaData(metadataID: 1, key: "key", value: "value")

        // When
        let dictionary = try metadata.toDictionary()

        // Then
        XCTAssertEqual(dictionary["id"] as? Int, 1)
        XCTAssertEqual(dictionary["key"] as? String, "key")
        XCTAssertEqual(dictionary["value"] as? String, "value")
    }

    func test_encode_metadataJson_to_dictionary() throws {
        // Given
        let metadata = MetaData(metadataID: 1, key: "key", value: "{\"key\":\"value\"}")

        // When
        let dictionary = try metadata.toDictionary()

        // Then
        let expectedValue = ["key": "value"]
        XCTAssertEqual(dictionary["id"] as? Int, 1)
        XCTAssertEqual(dictionary["key"] as? String, "key")
        XCTAssertEqual(dictionary["value"] as? [String: String], expectedValue)
    }

    func test_encode_metadataJsonArray_to_dictionary() throws {
        // Given
        let metadata = MetaData(metadataID: 1, key: "key", value: "[{\"key\":\"value\"}]")

        // When
        let dictionary = try metadata.toDictionary()

        // Then
        let expectedValue = [["key": "value"]]
        XCTAssertEqual(dictionary["id"] as? Int, 1)
        XCTAssertEqual(dictionary["key"] as? String, "key")
        XCTAssertEqual(dictionary["value"] as? [[String: String]], expectedValue)
    }
}
