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
        XCTAssertTrue(shippingLabelPackages.predefinedOptions.contains(sampleShippingLabelPredefinedOptions().first!))
        XCTAssertTrue(shippingLabelPackages.predefinedOptions.contains(sampleShippingLabelPredefinedOptions()[1]))
        XCTAssertTrue(shippingLabelPackages.unactivatedPredefinedOptions.contains(sampleShippingLabelUnactivatedPredefinedOption()))
        XCTAssertFalse(shippingLabelPackages.unactivatedPredefinedOptions.contains(sampleShippingLabelPredefinedOptions()[1]))
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
        let customPackage1 = ShippingLabelCustomPackage(isUserDefined: true,
                                                        title: "Krabica",
                                                        isLetter: false,
                                                        dimensions: "1 x 2 x 3",
                                                        boxWeight: 1,
                                                        maxWeight: 0)
        let customPackage2 = ShippingLabelCustomPackage(isUserDefined: true,
                                                        title: "Obalka",
                                                        isLetter: true,
                                                        dimensions: "2 x 3 x 4",
                                                        boxWeight: 5,
                                                        maxWeight: 0)

        return [customPackage1, customPackage2]
    }

    func sampleShippingLabelPredefinedOptions() -> [ShippingLabelPredefinedOption] {
        let predefinedPackages1 = [ShippingLabelPredefinedPackage(id: "small_flat_box",
                                                                  title: "Small Flat Rate Box",
                                                                  isLetter: false,
                                                                  dimensions: "21.91 x 13.65 x 4.13"),
                                  ShippingLabelPredefinedPackage(id: "medium_flat_box_top",
                                                                 title: "Medium Flat Rate Box 1, Top Loading",
                                                                 isLetter: false,
                                                                 dimensions: "28.57 x 22.22 x 15.24")]
        let predefinedOption1 = ShippingLabelPredefinedOption(title: "USPS Priority Mail Flat Rate Boxes",
                                                              providerID: "usps",
                                                              predefinedPackages: predefinedPackages1)

        let predefinedPackages2 = [ShippingLabelPredefinedPackage(id: "LargePaddedPouch",
                                                                  title: "Large Padded Pouch",
                                                                  isLetter: true,
                                                                  dimensions: "30.22 x 35.56 x 2.54")]
        let predefinedOption2 = ShippingLabelPredefinedOption(title: "DHL Express",
                                                              providerID: "dhlexpress",
                                                              predefinedPackages: predefinedPackages2)

        return [predefinedOption1, predefinedOption2]
    }

    func sampleShippingLabelUnactivatedPredefinedOption() -> ShippingLabelPredefinedOption {
        let predefinedPackages = [ShippingLabelPredefinedPackage(id: "SmallPaddedPouch",
                                                                  title: "Small Padded Pouch",
                                                                  isLetter: true,
                                                                  dimensions: "24.89 x 30.48 x 2.54"),
                                  ShippingLabelPredefinedPackage(id: "Box2Cube",
                                                                 title: "Box #2 Cube",
                                                                 isLetter: false,
                                                                 dimensions: "25.65 x 14.73 x 14.99"),
                                  ShippingLabelPredefinedPackage(id: "Box2Small",
                                                                 title: "Box #2 Small",
                                                                 isLetter: false,
                                                                 dimensions: "31.75 x 28.19 x 3.81"),
                                  ShippingLabelPredefinedPackage(id: "Box2Medium",
                                                                 title: "Box #2 Medium",
                                                                 isLetter: false,
                                                                 dimensions: "33.53 x 32 x 5.08"),
                                  ShippingLabelPredefinedPackage(id: "Box3Large",
                                                                 title: "Box #3 Large",
                                                                 isLetter: false,
                                                                 dimensions: "44.45 x 31.75 x 7.62")]
        let predefinedOption = ShippingLabelPredefinedOption(title: "DHL Express",
                                                             providerID: "dhlexpress",
                                                             predefinedPackages: predefinedPackages)

        return predefinedOption
    }
}
