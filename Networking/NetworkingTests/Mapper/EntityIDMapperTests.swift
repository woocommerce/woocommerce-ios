import XCTest
@testable import Networking

/// EntityIDMapper Unit Tests
///
final class EntityIDMapperTests: XCTestCase {

    private enum EntityIDMapperTestsError: Error {
        case unableToLoadFile
    }

    /// Verifies that IDs are parsed correctly.
    ///
    func test_id_is_properly_parsed() async throws {
        // Given
        let ids = try [await mapLoadIDsResponse(), await mapLoadIDsResponseWithoutData()]
        let expected: Int64 = 3946

        for id in ids {
            // Then
            XCTAssertEqual(id, expected)
        }
    }
}

/// Private Methods.
///
private extension EntityIDMapperTests {

    /// Returns the EntityIDMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapIDs(from filename: String) async throws -> Int64 {
        guard let response = Loader.contentsOf(filename) else {
            throw EntityIDMapperTestsError.unableToLoadFile
        }

        return try await EntityIDMapper().map(response: response)
    }

    /// Returns the EntityIDMapper output upon receiving `product-id-only`
    ///
    func mapLoadIDsResponse() async throws -> Int64 {
        try await mapIDs(from: "product-id-only")
    }

    /// Returns the EntityIDMapper output upon receiving `product-id-only-without-data`
    ///
    func mapLoadIDsResponseWithoutData() async throws -> Int64 {
        try await mapIDs(from: "product-id-only-without-data")
    }
}
