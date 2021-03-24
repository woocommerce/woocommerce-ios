import Foundation
import XCTest
@testable import Networking

/// Unit Tests for `ShippingLabelPackagesMapper`
///
final class ShippingLabelPackagesMapperTests: XCTestCase {

    /// Verifies that all of the ShippingLabelPackagesResponse Fields are parsed correctly.
    ///
    func test_ShippingLabelPackages_fields_are_properly_parsed() throws {
        let shippingLabelPackages = try XCTUnwrap(mapLoadShippingLabelPackagesResponse())

        XCTAssertEqual(shippingLabelPackages.storeOptions, sampleShippingLabelStoreOptions())
        XCTAssertEqual(shippingLabelPackages.customPackages, sampleShippingLabelCustomPackages())
    }
}

/// Private Helpers
///
private extension ShippingLabelPackagesMapperTests {
    /// Returns the ProductVariationMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapShippingLabelPackages(from filename: String) -> ShippingLabelPackagesResponse? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try? ShippingLabelPackagesMapper().map(response: response)
    }

    /// Returns the ShippingLabelPackagesMapper output upon receiving `filename`
    ///
    func mapLoadShippingLabelPackagesResponse() -> ShippingLabelPackagesResponse? {
        return mapShippingLabelPackages(from: "shipping-label-packages-success")
    }
}

private extension ShippingLabelPackagesMapperTests {
    func sampleShippingLabelStoreOptions() -> ShippingLabelStoreOptions {
        return ShippingLabelStoreOptions(currencySymbol: "$", dimensionUnit: "cm", weightUnit: "kg", originCountry: "US")
    }

    func sampleShippingLabelCustomPackages() -> [ShippingLabelCustomPackage] {
        let customPackage1 = ShippingLabelCustomPackage(isUserDefined: true, title: "Krabica", isLetter: false, dimensions: "1 x 2 x 3", boxWeight: 1, maxWeight: 0)
        let customPackage2 = ShippingLabelCustomPackage(isUserDefined: true, title: "Obalka", isLetter: true, dimensions: "2 x 3 x 4", boxWeight: 5, maxWeight: 0)
        
        return [customPackage1, customPackage2]
    }
    
    func sampleShippingLabelPredefinedOptions() -> [ShippingLabelPredefinedOption] {
        return []
    }
}
