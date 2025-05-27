import XCTest
@testable import Networking

/// Unit Tests for `ProductShippingClassListMapper`
///
final class ProductShippingClassListMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Verifies that all of the ProductShippingClass Fields are parsed correctly.
    ///
    func test_ProductShippingClass_fields_are_properly_parsed() throws {
        let productVariation = try XCTUnwrap(mapLoadAllProductShippingClassResponse()?.first)

        let expected = ProductShippingClass(count: 3,
                                            descriptionHTML: "Limited offer!",
                                            name: "Free Shipping",
                                            shippingClassID: 94,
                                            siteID: dummySiteID,
                                            slug: "free-shipping")

        XCTAssertEqual(productVariation, expected)
    }

    /// Verifies that all of the ProductShippingClass Fields are parsed correctly when response has no data envelope.
    ///
    func test_ProductShippingClass_fields_are_properly_parsed_when_response_has_no_data_envelope() throws {
        let productVariation = try XCTUnwrap(mapLoadAllProductShippingClassResponseWithoutDataEnvelope()?.first)

        let expected = ProductShippingClass(count: 3,
                                            descriptionHTML: "Limited offer!",
                                            name: "Free Shipping",
                                            shippingClassID: 94,
                                            siteID: dummySiteID,
                                            slug: "free-shipping")

        XCTAssertEqual(productVariation, expected)
    }
}

/// Private Helpers
///
private extension ProductShippingClassListMapperTests {
    /// Returns the ProductShippingClassListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductShippingClass(from filename: String) -> [ProductShippingClass]? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try? ProductShippingClassListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ProductShippingClassListMapper output upon receiving `product-shipping-classes-load-all`
    ///
    func mapLoadAllProductShippingClassResponse() -> [ProductShippingClass]? {
        return mapProductShippingClass(from: "product-shipping-classes-load-all")
    }

    /// Returns the ProductShippingClassListMapper output upon receiving `product-shipping-classes-load-all-without-data`
    ///
    func mapLoadAllProductShippingClassResponseWithoutDataEnvelope() -> [ProductShippingClass]? {
        return mapProductShippingClass(from: "product-shipping-classes-load-all-without-data")
    }
}
