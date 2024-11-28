import XCTest
@testable import Networking

final class ProductTagListMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Verifies that all of the ProductTag Fields are parsed correctly.
    ///
    func test_ProductTag_fields_are_properly_parsed() throws {
        let tags = try mapLoadAllProductTagsResponse()
        XCTAssertEqual(tags.count, 4)

        let secondTag = tags[1]
        XCTAssertEqual(secondTag.tagID, 35)
        XCTAssertEqual(secondTag.name, "Oxford Shoes")
        XCTAssertEqual(secondTag.slug, "oxford-shoes")
    }

    /// Verifies that all of the ProductTag Fields are parsed correctly.
    ///
    func test_ProductTag_fields_are_properly_parsed_when_response_has_no_data_envelope() throws {
        let tags = try mapLoadAllProductTagsResponseWithoutDataEnvelope()
        XCTAssertEqual(tags.count, 4)

        let secondTag = tags[1]
        XCTAssertEqual(secondTag.tagID, 35)
        XCTAssertEqual(secondTag.name, "Oxford Shoes")
        XCTAssertEqual(secondTag.slug, "oxford-shoes")
    }

    /// Verifies that all of the ProductTag Fields under `create` field are parsed correctly.
    ///
    func test_ProductTag_fields_when_created_are_properly_parsed() throws {
        let tags = try mapLoadProductTagsCreatedResponse()
        XCTAssertEqual(tags.count, 2)

        let firstTag = tags[0]
        XCTAssertEqual(firstTag.tagID, 36)
        XCTAssertEqual(firstTag.name, "Round toe")
        XCTAssertEqual(firstTag.slug, "round-toe")
    }

    /// Verifies that all of the ProductTag Fields under `create` field are parsed correctly.
    ///
    func test_ProductTag_fields_when_created_are_properly_parsed_when_response_has_no_data_envelope() throws {
        let tags = try mapLoadProductTagsCreatedResponseWithoutDataEnvelope()
        XCTAssertEqual(tags.count, 2)

        let firstTag = tags[0]
        XCTAssertEqual(firstTag.tagID, 36)
        XCTAssertEqual(firstTag.name, "Round toe")
        XCTAssertEqual(firstTag.slug, "round-toe")
    }

    /// Verifies that all of the ProductTag Fields under `delete` field are parsed correctly.
    ///
    func test_ProductTag_fields_when_deleted_are_properly_parsed() throws {
        let tags = try mapLoadProductTagsDeletedResponse()
        XCTAssertEqual(tags.count, 1)

        let firstTag = tags[0]
        XCTAssertEqual(firstTag.tagID, 35)
        XCTAssertEqual(firstTag.name, "Oxford Shoes")
        XCTAssertEqual(firstTag.slug, "oxford-shoes")
    }

    /// Verifies that all of the ProductTag Fields under `delete` field are parsed correctly.
    ///
    func test_ProductTag_fields_when_deleted_are_properly_parsed_when_response_has_no_data_envelope() throws {
        let tags = try mapLoadProductTagsDeletedResponseWithoutDataEnvelope()
        XCTAssertEqual(tags.count, 1)

        let firstTag = tags[0]
        XCTAssertEqual(firstTag.tagID, 35)
        XCTAssertEqual(firstTag.name, "Oxford Shoes")
        XCTAssertEqual(firstTag.slug, "oxford-shoes")
    }
}


/// Private Methods.
///
private extension ProductTagListMapperTests {

    /// Returns the ProductTagListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductTags(from filename: String, responseType: ProductTagListMapper.ResponseType) throws -> [ProductTag] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try ProductTagListMapper(siteID: dummySiteID, responseType: responseType).map(response: response)
    }

    /// Returns the ProductTagListMapper output upon receiving `product-tags-all`
    ///
    func mapLoadAllProductTagsResponse() throws -> [ProductTag] {
        return try mapProductTags(from: "product-tags-all", responseType: .load)
    }

    /// Returns the ProductTagListMapper output upon receiving `product-tags-all-without-data`
    ///
    func mapLoadAllProductTagsResponseWithoutDataEnvelope() throws -> [ProductTag] {
        return try mapProductTags(from: "product-tags-all-without-data", responseType: .load)
    }

    /// Returns the ProductTagListMapper output upon receiving `product-tags-created`
    ///
    func mapLoadProductTagsCreatedResponse() throws -> [ProductTag] {
        return try mapProductTags(from: "product-tags-created", responseType: .create)
    }

    /// Returns the ProductTagListMapper output upon receiving `product-tags-created-without-data`
    ///
    func mapLoadProductTagsCreatedResponseWithoutDataEnvelope() throws -> [ProductTag] {
        return try mapProductTags(from: "product-tags-created-without-data", responseType: .create)
    }

    /// Returns the ProductTagListMapper output upon receiving `product-tags-deleted`
    ///
    func mapLoadProductTagsDeletedResponse() throws -> [ProductTag] {
        return try mapProductTags(from: "product-tags-deleted", responseType: .delete)
    }

    /// Returns the ProductTagListMapper output upon receiving `product-tags-deleted-without-data`
    ///
    func mapLoadProductTagsDeletedResponseWithoutDataEnvelope() throws -> [ProductTag] {
        return try mapProductTags(from: "product-tags-deleted-without-data", responseType: .delete)
    }
}
