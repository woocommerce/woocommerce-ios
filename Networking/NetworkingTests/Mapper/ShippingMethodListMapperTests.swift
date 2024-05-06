import XCTest
@testable import Networking

final class ShippingMethodListMapperTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345

    /// Verifies that the whole list is parsed.
    ///
    func test_shipping_method_list_is_properly_parsed() throws {
        // Given
        let shippingMethods = try mapLoadShippingMethodsResponse()

        // Assert
        assertEqual(6, shippingMethods.count)

        // Then
        let method = try XCTUnwrap(shippingMethods.first)

        // Assert
        assertEqual(sampleSiteID, method.siteID)
        assertEqual("flat_rate", method.methodID)
        assertEqual("Flat rate", method.title)
    }
}

// MARK: - Test Helpers
private extension ShippingMethodListMapperTests {

    /// Returns the mapShippingMethodListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapShippingMethods(from filename: String) throws -> [ShippingMethod] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try ShippingMethodListMapper(siteID: sampleSiteID).map(response: response)
    }

    /// Returns the ShippingMethodListMapper output from `shipping-methods.json`
    ///
    func mapLoadShippingMethodsResponse() throws -> [ShippingMethod] {
        return try mapShippingMethods(from: "shipping-methods")
    }
}
