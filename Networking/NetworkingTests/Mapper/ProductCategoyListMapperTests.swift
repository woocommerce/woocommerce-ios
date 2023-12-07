import XCTest
@testable import Networking

final class ProductCategoryListMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Verifies that all of the ProductCategory Fields are parsed correctly.
    ///
    func test_ProductCategory_fields_are_properly_parsed() async throws {
        let productCategories = try await mapLoadAllProductCategoriesResponse()
        XCTAssertEqual(productCategories.count, 2)

        let secondProductCategory = productCategories[1]
        XCTAssertEqual(secondProductCategory.categoryID, 20)
        XCTAssertEqual(secondProductCategory.parentID, 17)
        XCTAssertEqual(secondProductCategory.siteID, dummySiteID)
        XCTAssertEqual(secondProductCategory.name, "American")
        XCTAssertEqual(secondProductCategory.slug, "american")
    }

    /// Verifies that all of the ProductCategory Fields are parsed correctly.
    ///
    func test_ProductCategory_fields_are_properly_parsed_when_response_has_no_data_envelope() async throws {
        let productCategories = try await mapLoadAllProductCategoriesResponseWithoutDataEnvelope()
        XCTAssertEqual(productCategories.count, 2)

        let secondProductCategory = productCategories[1]
        XCTAssertEqual(secondProductCategory.categoryID, 20)
        XCTAssertEqual(secondProductCategory.parentID, 17)
        XCTAssertEqual(secondProductCategory.siteID, dummySiteID)
        XCTAssertEqual(secondProductCategory.name, "American")
        XCTAssertEqual(secondProductCategory.slug, "american")
    }

    /// Verifies that all of the ProductCategory Fields under `create` field are parsed correctly.
    ///
    func test_ProductCategory_fields_when_created_are_properly_parsed() async throws {
        let categories = try await mapLoadProductCategoriesCreatedResponse()
        XCTAssertEqual(categories.count, 1)

        let first = categories[0]
        XCTAssertEqual(first.categoryID, 21)
        XCTAssertEqual(first.parentID, 3)
        XCTAssertEqual(first.siteID, dummySiteID)
        XCTAssertEqual(first.name, "Headphone")
        XCTAssertEqual(first.slug, "headphone")
    }

    /// Verifies that all of the ProductCategory Fields under `create` field are parsed correctly without data enveloper.
    ///
    func test_ProductCategory_fields_when_created_are_properly_parsed_when_response_has_no_data_envelope() async throws {
        let categories = try await mapLoadProductCategoriesCreatedResponseWithoutDataEnvelope()
        XCTAssertEqual(categories.count, 1)

        let first = categories[0]
        XCTAssertEqual(first.categoryID, 21)
        XCTAssertEqual(first.parentID, 3)
        XCTAssertEqual(first.siteID, dummySiteID)
        XCTAssertEqual(first.name, "Headphone")
        XCTAssertEqual(first.slug, "headphone")
    }
}


/// Private Methods.
///
private extension ProductCategoryListMapperTests {

    /// Returns the ProducCategoryListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductCategories(from filename: String, responseType: ProductCategoryListMapper.ResponseType) async throws -> [ProductCategory] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try await ProductCategoryListMapper(siteID: dummySiteID, responseType: responseType).map(response: response)
    }

    /// Returns the ProductCategoryListMapper output upon receiving `categories-all`
    ///
    func mapLoadAllProductCategoriesResponse() async throws -> [ProductCategory] {
        try await mapProductCategories(from: "categories-all", responseType: .load)
    }

    /// Returns the ProductCategoryListMapper output upon receiving `categories-all-without-data`
    ///
    func mapLoadAllProductCategoriesResponseWithoutDataEnvelope() async throws -> [ProductCategory] {
        try await mapProductCategories(from: "categories-all-without-data", responseType: .load)
    }

    /// Returns the ProductCategoryListMapper output upon receiving `product-categories-created`
    ///
    func mapLoadProductCategoriesCreatedResponse() async throws -> [ProductCategory] {
        try await mapProductCategories(from: "product-categories-created", responseType: .create)
    }

    /// Returns the ProductCategoryListMapper output upon receiving `product-categories-created-without-data`
    ///
    func mapLoadProductCategoriesCreatedResponseWithoutDataEnvelope() async throws -> [ProductCategory] {
        try await mapProductCategories(from: "product-categories-created-without-data", responseType: .create)
    }
}
