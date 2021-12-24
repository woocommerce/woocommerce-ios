import XCTest
@testable import WooCommerce

final class ProductFactoryTests: XCTestCase {
    private let siteID: Int64 = 134

    func test_created_simple_physical_product_has_expected_fields() throws {
        let product = try XCTUnwrap(ProductFactory().createNewProduct(type: .simple, isVirtual: false, siteID: siteID))
        XCTAssertEqual(product.productType, .simple)
        XCTAssertEqual(product.virtual, false)
        XCTAssertEqual(product.siteID, siteID)
    }

    func test_created_simple_virtual_product_has_expected_fields() throws {
        let product = try XCTUnwrap(ProductFactory().createNewProduct(type: .simple, isVirtual: true, siteID: siteID))
        XCTAssertEqual(product.productType, .simple)
        XCTAssertEqual(product.virtual, true)
        XCTAssertEqual(product.siteID, siteID)
    }

    func test_created_grouped_product_has_expected_fields() throws {
        let product = try XCTUnwrap(ProductFactory().createNewProduct(type: .grouped, isVirtual: false, siteID: siteID))
        XCTAssertEqual(product.productType, .grouped)
        XCTAssertEqual(product.siteID, siteID)
    }

    func test_created_external_product_has_expected_fields() throws {
        let product = try XCTUnwrap(ProductFactory().createNewProduct(type: .affiliate, isVirtual: false, siteID: siteID))
        XCTAssertEqual(product.productType, .affiliate)
        XCTAssertEqual(product.siteID, siteID)
    }

    func test_created_variable_product_has_expected_fields() throws {
        let product = try XCTUnwrap(ProductFactory().createNewProduct(type: .variable, isVirtual: false, siteID: siteID))
        XCTAssertEqual(product.productType, .variable)
        XCTAssertEqual(product.siteID, siteID)
    }

    func test_creating_a_non_core_product_returns_nil() {
        let product = ProductFactory().createNewProduct(type: .custom("any"), isVirtual: false, siteID: siteID)
        XCTAssertNil(product)
    }
}
