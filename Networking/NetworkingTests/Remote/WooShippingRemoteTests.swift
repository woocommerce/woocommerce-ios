import XCTest
import TestKit
@testable import Networking

/// WooShippingTests Unit Tests
///
final class WooShippingRemoteTests: XCTestCase {
    /// Dummy Network Wrapper
    private let network = MockNetwork()

    /// Dummy Site ID
    private let sampleSiteID: Int64 = 1234

    /// Dummy Order ID
    private let sampleOrderID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    func test_createPackage_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "wooshipping-create-package-success")

        // When
        let result: Result<WooShippingCreatePackageResponse, Error> = waitFor { promise in
            remote.createPackage(siteID: self.sampleSiteID,
                                 customPackage: WooShippingCustomPackage.fake(),
                                 predefinedOption: WooShippingPredefinedSavedOption.fake()) { result in
                promise(result)
            }
        }

        // Then
        let packagesResponse = try XCTUnwrap(result.get())
        XCTAssertEqual(packagesResponse.customPackages.count, 5)
        XCTAssertEqual(packagesResponse.predefinedOptions.count, 1)
    }

    func test_createPackage_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "wooshipping-create-package-error")

        // When
        let result: Result<WooShippingCreatePackageResponse, Error> = waitFor { promise in
            remote.createPackage(siteID: self.sampleSiteID,
                                 customPackage: WooShippingCustomPackage.fake(),
                                 predefinedOption: WooShippingPredefinedSavedOption.fake()) { result in
                promise(result)
            }
        }

        // Then
        let expectedError = DotcomError
            .unknown(code: "duplicate_custom_package_names_of_existing_packages",
                     message: "At least one of the new custom packages has the same name as existing packages.")
        XCTAssertEqual(result.failure as? DotcomError, expectedError)
    }

    func test_createPackage_returns_missingPackage_error_with_no_packages() throws {
        // Given
        let remote = WooShippingRemote(network: network)

        // When
        let result: Result<WooShippingCreatePackageResponse, Error> = waitFor { promise in
            remote.createPackage(siteID: self.sampleSiteID,
                                 customPackage: nil,
                                 predefinedOption: nil) { result in
                promise(result)
            }
        }

        // Then
        let expectedError = WooShippingRemote.ShippingError.missingPackage
        XCTAssertEqual(result.failure as? WooShippingRemote.ShippingError, expectedError)
    }

    func test_loadLabelRates_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/rate", filename: "wooshipping-get-label-rates-success")
        let expectedDefaultRate = sampleLabelRate()

        // When
        let result: Result<[ShippingLabelCarriersAndRates], Error> = waitFor { promise in
            remote.loadLabelRates(siteID: self.sampleSiteID,
                                  orderID: self.sampleOrderID,
                                  originAddress: ShippingLabelAddress.fake(), destinationAddress: ShippingLabelAddress.fake(),
                                  packages: [ShippingLabelPackageSelected.fake()]) { (result) in
                promise(result)
            }
        }

        // Then
        let successResponse = try XCTUnwrap(result.get())
        XCTAssertEqual(successResponse.first?.defaultRates.first, expectedDefaultRate)
    }

    func test_loadLabelRates_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/rate", filename: "generic_error")

        // When
        let result: Result<[ShippingLabelCarriersAndRates], Error> = waitFor { promise in
            remote.loadLabelRates(siteID: self.sampleSiteID,
                                  orderID: self.sampleOrderID,
                                  originAddress: ShippingLabelAddress.fake(), destinationAddress: ShippingLabelAddress.fake(),
                                  packages: [ShippingLabelPackageSelected.fake()]) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_loadPackages_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "wooshipping-get-packages-success")

        // When
        let result: Result<WooShippingPackagesResponse, Error> = waitFor { promise in
            remote.loadPackages(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let successResponse = try XCTUnwrap(result.get())
        XCTAssertEqual(successResponse.savedPredefinedOptions.count, 1)
        XCTAssertEqual(successResponse.savedPredefinedOptions.first?.id, "usps")
        XCTAssertEqual(successResponse.savedPredefinedOptions.first?.predefinedPackageIDs.count, 2)
    }

    func test_loadPackages_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "generic_error")

        // When
        let result: Result<WooShippingPackagesResponse, Error> = waitFor { promise in
            remote.loadPackages(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }
}

private extension WooShippingRemoteTests {
    func sampleLabelRate() -> ShippingLabelCarrierRate {
        ShippingLabelCarrierRate(title: "USPS - Media Mail",
                                 insurance: "0.0",
                                 retailRate: 6.13,
                                 rate: 6.13,
                                 rateID: "rate_fd16937cc3a14cb9b28e160a06cf3e34",
                                 serviceID: "MediaMail",
                                 carrierID: "usps",
                                 shipmentID: "shp_abc123",
                                 hasTracking: true,
                                 isSelected: false,
                                 isPickupFree: false,
                                 deliveryDays: 7,
                                 deliveryDateGuaranteed: false)
    }
}
