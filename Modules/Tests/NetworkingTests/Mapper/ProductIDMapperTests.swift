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
    func test_id_is_properly_parsed() throws {
        // Given
        let ids = try [mapLoadIDsResponse(), mapLoadIDsResponseWithoutData()]
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
    func mapIDs(from filename: String) throws -> [Int64] {
        guard let response = Loader.contentsOf(filename) else {
            throw ProductIDMapperTestsError.unableToLoadFile
        }

        return try! ProductIDMapper().map(response: response)
    }

    /// Returns the ProductIDMapper output upon receiving `products-ids-only`
    ///
    func mapLoadIDsResponse() throws -> [Int64] {
        try mapIDs(from: "products-ids-only")
    }

    /// Returns the ProductIDMapper output upon receiving `products-ids-only-without-data`
    ///
    func mapLoadIDsResponseWithoutData() throws -> [Int64] {
        try mapIDs(from: "products-ids-only-without-data")
    }
}
