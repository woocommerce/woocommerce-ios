import XCTest
@testable import WooCommerce
@testable import ParcelFittingCheck

final class WooShippingPackageDataFromResultTests: XCTestCase {

    func test_from_when_carrier_package_matches_then_uses_predefined_source() {
        // Given
        let package = ParcelPresetPackage(id: "usps_medium", name: "Medium Box", length: 11, width: 8.5, height: 5.5)
        let carrier = ParcelPresetCarrier(id: "usps", name: "USPS", packages: [package])
        let result = ParcelFittingResult.carrierPackage(package, measurement: ParcelDimensions(length: 10, width: 8, height: 5))

        // When
        let packageData = WooShippingPackageData.from(result, carriers: [carrier])

        // Then
        XCTAssertEqual(packageData.id, "usps_medium")
        XCTAssertEqual(packageData.name, "Medium Box")
        if case .predefined(let title, let sourceID) = packageData.source {
            XCTAssertEqual(title, "USPS")
            XCTAssertEqual(sourceID, "usps")
        } else {
            XCTFail("Expected predefined source")
        }
    }

    func test_from_when_carrier_not_found_then_falls_back_to_custom_source() {
        // Given
        let package = ParcelPresetPackage(id: "unknown_pkg", name: "Unknown", length: 10, width: 8, height: 5)
        let result = ParcelFittingResult.carrierPackage(package, measurement: ParcelDimensions(length: 9, width: 7, height: 4))

        // When
        let packageData = WooShippingPackageData.from(result, carriers: [])

        // Then
        XCTAssertEqual(packageData.id, "unknown_pkg")
        if case .custom = packageData.source {} else {
            XCTFail("Expected custom source when carrier not found")
        }
    }

    func test_from_when_custom_dimensions_then_uses_custom_source() {
        // Given
        let dims = ParcelDimensions(length: 12.5, width: 8.3, height: 4.1)
        let result = ParcelFittingResult.customDimensions(dims)

        // When
        let packageData = WooShippingPackageData.from(result, carriers: [])

        // Then
        XCTAssertEqual(packageData.id, "custom_box")
        XCTAssertEqual(packageData.length, ParcelDimensions.formatValue(12.5))
        XCTAssertEqual(packageData.width, ParcelDimensions.formatValue(8.3))
        XCTAssertEqual(packageData.height, ParcelDimensions.formatValue(4.1))
        if case .custom = packageData.source {} else {
            XCTFail("Expected custom source")
        }
    }
}
