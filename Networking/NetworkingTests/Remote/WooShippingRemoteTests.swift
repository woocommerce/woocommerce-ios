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

    /// Dummy Shipment ID
    private let sampleShipmentID: String = "shipment_0"

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
        let expectedCustomPackage = sampleCustomPackage()

        // When
        let result: Result<WooShippingPackagesResponse, Error> = waitFor { promise in
            remote.loadPackages(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let successResponse = try XCTUnwrap(result.get())
        XCTAssertEqual(successResponse.savedPredefinedPackages.count, 2)
        XCTAssertEqual(successResponse.savedPredefinedPackages.first?.package.groupId, "pri_flat_boxes")
        XCTAssertEqual(successResponse.savedPredefinedPackages.first?.groupTitle, "USPS Priority Mail Flat Rate Boxes")
        XCTAssertEqual(successResponse.savedPredefinedPackages.first?.providerID, "usps")

        XCTAssertEqual(successResponse.customPackages.count, 1)
        XCTAssertEqual(successResponse.customPackages.first, expectedCustomPackage)

        XCTAssertEqual(successResponse.allPredefinedOptions.count, 2)
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

    func test_loadAccountSettings_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "account/settings", filename: "wooshipping-get-account-settings-success")

        // When
        let result: Result<WooShippingAccountSettingsResponse, Error> = waitFor { promise in
            remote.loadAccountSettings(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let successResponse = try XCTUnwrap(result.get())
        XCTAssertEqual(successResponse.storeOptions.currencySymbol, "$")
        XCTAssertEqual(successResponse.storeOptions.dimensionUnit, "cm")
        XCTAssertEqual(successResponse.storeOptions.weightUnit, "kg")
        XCTAssertEqual(successResponse.storeOptions.originCountry, "US")

        XCTAssertEqual(successResponse.accountSettings.canManagePayments, false)
        XCTAssertEqual(successResponse.accountSettings.canEditSettings, true)
        XCTAssertEqual(successResponse.accountSettings.storeOwnerDisplayName, "Rachel")
        XCTAssertEqual(successResponse.accountSettings.storeOwnerUsername, "rachelmcr")
        XCTAssertEqual(successResponse.accountSettings.storeOwnerWpcomUsername, "rachelmcr")
        XCTAssertEqual(successResponse.accountSettings.storeOwnerWpcomEmail, "rachel@automattic.com")

        XCTAssertEqual(successResponse.accountSettings.paymentMethods.count, 1)
        XCTAssertEqual(successResponse.accountSettings.paymentMethods.first?.paymentMethodID, 3190997)
        XCTAssertEqual(successResponse.accountSettings.paymentMethods.first?.name, "Test User")
        XCTAssertEqual(successResponse.accountSettings.paymentMethods.first?.cardType, .visa)
        XCTAssertEqual(successResponse.accountSettings.paymentMethods.first?.cardDigits, "4242")

        XCTAssertEqual(successResponse.accountSettings.selectedPaymentMethodID, 3190997)
        XCTAssertEqual(successResponse.accountSettings.isEmailReceiptsEnabled, true)
        XCTAssertEqual(successResponse.accountSettings.paperSize, .label)
        XCTAssertEqual(successResponse.accountSettings.lastSelectedPackageID, "")
    }

    func test_loadAccountSettings_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "account/settings", filename: "generic_error")

        // When
        let result: Result<WooShippingAccountSettingsResponse, Error> = waitFor { promise in
            remote.loadAccountSettings(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_purchaseShippingLabel_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/purchase/\(sampleOrderID)", filename: "wooshipping-purchase-success")

        // When
        let result: Result<[ShippingLabelPurchase], Error> = waitFor { promise in
            remote.purchaseShippingLabel(siteID: self.sampleSiteID,
                                         orderID: self.sampleOrderID,
                                         originAddress: ShippingLabelAddress.fake(),
                                         destinationAddress: ShippingLabelAddress.fake(),
                                         package: WooShippingPackagePurchase.fake()) { result in
                promise(result)
            }
        }

        // Then
        let labels = try XCTUnwrap(result.get())
        XCTAssertEqual(labels.count, 1)
    }

    func test_purchaseShippingLabel_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/purchase/\(sampleOrderID)", filename: "generic_error")

        // When
        let result: Result<[ShippingLabelPurchase], Error> = waitFor { promise in
            remote.purchaseShippingLabel(siteID: self.sampleSiteID,
                                         orderID: self.sampleOrderID,
                                         originAddress: ShippingLabelAddress.fake(),
                                         destinationAddress: ShippingLabelAddress.fake(),
                                         package: WooShippingPackagePurchase.fake()) { result in
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

    func sampleCustomPackage() -> WooShippingCustomPackage {
        WooShippingCustomPackage(id: "849225dc153",
                                 name: "Custom name",
                                 rawType: "box",
                                 dimensions: "12 x 12 x 12",
                                 boxWeight: 0.01)
    }
}
