import XCTest
@testable import Networking

final class MetaDataMapperTests: XCTestCase {

    func test_it_maps_MetaData_correctly_from_meta_data_response() throws {
        // Given
        let data = try retrieveMetaDataResponse()
        let mapper = MetaDataMapper()

        // When
        let metadata = try mapper.map(response: data)

        // Then
        XCTAssertEqual(metadata.count, 4)

        XCTAssertEqual(metadata[0].metadataID, 1)
        XCTAssertEqual(metadata[0].key, "lorem_key_1")
        XCTAssertEqual(metadata[0].value, "Lorem ipsum")

        XCTAssertEqual(metadata[1].metadataID, 2)
        XCTAssertEqual(metadata[1].key, "ipsum_key_2")
        XCTAssertEqual(metadata[1].value, "dolor sit amet")

        XCTAssertEqual(metadata[2].metadataID, 3)
        XCTAssertEqual(metadata[2].key, "dolor_key_3")
        XCTAssertEqual(metadata[2].value, "consectetur adipiscing elit")

        XCTAssertEqual(metadata[3].metadataID, 4)
        XCTAssertEqual(metadata[3].key, "sit_key_4")
        XCTAssertEqual(metadata[3].value, "Nisi ut aliquip")
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

    struct FileNotFoundError: Error {}
}
