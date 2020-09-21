import XCTest

@testable import WooCommerce

final class ProductFactoryTests: XCTestCase {
    private let siteID: Int64 = 134

    func test_created_simple_product_has_expected_fields() throws {
        let product = try XCTUnwrap(ProductFactory().createNewProduct(type: .simple, siteID: siteID))
        XCTAssertEqual(product.productType, .simple)
        XCTAssertEqual(product.siteID, siteID)
    }

    func test_created_grouped_product_has_expected_fields() throws {
        let product = try XCTUnwrap(ProductFactory().createNewProduct(type: .grouped, siteID: siteID))
        XCTAssertEqual(product.productType, .grouped)
        XCTAssertEqual(product.siteID, siteID)
    }

    func test_created_external_product_has_expected_fields() throws {
        let product = try XCTUnwrap(ProductFactory().createNewProduct(type: .affiliate, siteID: siteID))
        XCTAssertEqual(product.productType, .affiliate)
        XCTAssertEqual(product.siteID, siteID)
    }

    func test_created_variable_product_has_expected_fields() throws {
        let product = try XCTUnwrap(ProductFactory().createNewProduct(type: .variable, siteID: siteID))
        XCTAssertEqual(product.productType, .variable)
        XCTAssertEqual(product.siteID, siteID)
    }

    func test_creating_a_non_core_product_returns_nil() {
        let product = ProductFactory().createNewProduct(type: .custom("any"), siteID: siteID)
        XCTAssertNil(product)
    }
}
