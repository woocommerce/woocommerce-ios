import XCTest
@testable import Networking

/// ProductIDMapper Unit Tests
///
final class ProductIDMapperTests: XCTestCase {

    private enum ProductIDMapperTestsError: Error {
        case unableToLoadFile
    }

    /// Verifies that IDs are parsed correctly.
    ///
    func test_id_is_properly_parsed() async throws {
        // Given
        let ids = try [await mapLoadIDsResponse(), await mapLoadIDsResponseWithoutData()]
        let expected: [Int64] = [3946]

        for id in ids {
            // Then
            XCTAssertEqual(id, expected)
        }
    }
}


/// Private Methods.
///
private extension ProductIDMapperTests {

    /// Returns the ProductIDMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapIDs(from filename: String) async throws -> [Int64] {
        guard let response = Loader.contentsOf(filename) else {
            throw ProductIDMapperTestsError.unableToLoadFile
        }

        return try await ProductIDMapper().map(response: response)
    }

    /// Returns the ProductIDMapper output upon receiving `products-ids-only`
    ///
    func mapLoadIDsResponse() async throws -> [Int64] {
        try await mapIDs(from: "products-ids-only")
    }

    /// Returns the ProductIDMapper output upon receiving `products-ids-only-without-data`
    ///
    func mapLoadIDsResponseWithoutData() async throws -> [Int64] {
        try await mapIDs(from: "products-ids-only-without-data")
    }
}
