import XCTest
import TestKit
@testable import Networking

/// ShippingLabelRemote Unit Tests
///
final class ShippingLabelRemoteTests: XCTestCase {
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

    func test_loadShippingLabels_returns_shipping_labels_and_settings() throws {
        // Given
        let orderID: Int64 = 630
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(orderID)", filename: "order-shipping-labels")

        // When
        let result = waitFor { promise in
            remote.loadShippingLabels(siteID: self.sampleSiteID, orderID: orderID) { result in
                promise(result)
            }
        }

        // Then
        let response = try XCTUnwrap(result.get())
        XCTAssertEqual(response.settings, .init(siteID: sampleSiteID, orderID: orderID, paperSize: .label))
        XCTAssertEqual(response.shippingLabels.count, 2)
        XCTAssertNotNil(response.shippingLabels.first?.commercialInvoiceURL)
    }

    func test_printShippingLabel_returns_ShippingLabelPrintData() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/print", filename: "shipping-label-print")

        // When
        let printData: ShippingLabelPrintData = waitFor { promise in
            remote.printShippingLabel(siteID: self.sampleSiteID, shippingLabelIDs: [123], paperSize: .label) { result in
                guard let printData = try? result.get() else {
                    XCTFail("Error printing shipping label: \(String(describing: result.failure))")
                    return
                }
                promise(printData)
            }
        }

        // Then
        XCTAssertEqual(printData.mimeType, "application/pdf")
        XCTAssertFalse(printData.base64Content.isEmpty)
    }

    func test_refundShippingLabel_returns_refund_on_success() throws {
        // Given
        let orderID = Int64(279)
        let shippingLabelID = Int64(134)
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(orderID)/\(shippingLabelID)/refund", filename: "shipping-label-refund-success")

        // When
        let result: Result<ShippingLabelRefund, Error> = waitFor { promise in
            remote.refundShippingLabel(siteID: self.sampleSiteID,
                                       orderID: orderID,
                                       shippingLabelID: shippingLabelID) { result in
                promise(result)
            }
        }

        // Then
        let refund = try XCTUnwrap(result.get())
        XCTAssertEqual(refund, .init(dateRequested: Date(timeIntervalSince1970: 1607331363.627), status: .pending))
    }

    func test_refundShippingLabel_returns_error_on_failure() throws {
        // Given
        let orderID = Int64(279)
        let shippingLabelID = Int64(134)
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(orderID)/\(shippingLabelID)/refund", filename: "shipping-label-refund-error")

        // When
        let result: Result<ShippingLabelRefund, Error> = waitFor { promise in
            remote.refundShippingLabel(siteID: self.sampleSiteID,
                                       orderID: orderID,
                                       shippingLabelID: shippingLabelID) { result in
                promise(result)
            }
        }

        // Then
        let expectedError = DotcomError
            .unknown(code: "wcc_server_error_response",
                     message: "Error: The WooCommerce Shipping & Tax server returned: Bad Request Unable to request refund. " +
                        "The parcel has been shipped. ( 400 )")
        XCTAssertEqual(result.failure as? DotcomError, expectedError)
    }

    func test_shippingAddressValidation_returns_address_on_success() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "normalize-address", filename: "shipping-label-address-validation-success")

        // When
        let result: Result<ShippingLabelAddressValidationSuccess, Error> = waitFor { promise in
            remote.addressValidation(siteID: self.sampleSiteID, address: self.sampleShippingLabelAddressVerification()) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.address, sampleShippingLabelAddress())
        case .failure(let error):
            XCTFail("Expected successful result, got error instead: \(error)")
        }
    }

    func test_shippingAddressValidation_returns_address_without_name_on_success() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "normalize-address", filename: "shipping-label-address-without-name-validation-success")

        // When
        let result: Result<ShippingLabelAddressValidationSuccess, Error> = waitFor { promise in
            remote.addressValidation(siteID: self.sampleSiteID, address: self.sampleShippingLabelAddressWithoutNameVerification()) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let response):
            XCTAssertEqual(response.address, sampleShippingLabelAddressWithoutName())
        case .failure(let error):
            XCTFail("Expected successful result, got error instead: \(error)")
        }
    }

    func test_shippingAddressValidation_returns_errors_on_failure() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "normalize-address", filename: "shipping-label-address-validation-error")

        // When
        let result: Result<ShippingLabelAddressValidationSuccess, Error> = waitFor { promise in
            remote.addressValidation(siteID: self.sampleSiteID, address: self.sampleShippingLabelAddressVerification()) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let response):
            XCTFail("Expected validation error, got successful response instead: \(response)")
        case .failure(let error as ShippingLabelAddressValidationError):
            XCTAssertEqual(error.addressError, "House number is missing")
            XCTAssertEqual(error.generalError, "Address not found")
        case .failure(let error):
            XCTFail("Expected validation error, got generic error instead: \(error)")
        }
    }

    func test_packagesDetails_returns_packages_on_success() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "shipping-label-packages-success")

        // When
        let result: Result<ShippingLabelPackagesResponse, Error> = waitFor { promise in
            remote.packagesDetails(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(try result.get())
    }

    func test_packagesDetails_returns_errors_on_failure() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "generic_error")

        // When
        let result: Result<ShippingLabelPackagesResponse, Error> = waitFor { promise in
            remote.packagesDetails(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_createPackage_parses_success_response() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "generic_success_data")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.createPackage(siteID: self.sampleSiteID,
                                 customPackage: ShippingLabelCustomPackage.fake(),
                                 predefinedOption: ShippingLabelPredefinedOption.fake()) { result in
                promise(result)
            }
        }

        // Then
        let successResponse = try XCTUnwrap(result.get())
        XCTAssertTrue(successResponse)
    }

    func test_createPackage_returns_success_response_with_only_custom_package() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "generic_success_data")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.createPackage(siteID: self.sampleSiteID,
                                 customPackage: ShippingLabelCustomPackage.fake(),
                                 predefinedOption: nil) { result in
                promise(result)
            }
        }

        // Then
        let successResponse = try XCTUnwrap(result.get())
        XCTAssertTrue(successResponse)
    }

    func test_createPackage_returns_success_response_with_only_service_package() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "generic_success_data")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.createPackage(siteID: self.sampleSiteID,
                                 customPackage: nil,
                                 predefinedOption: ShippingLabelPredefinedOption.fake()) { result in
                promise(result)
            }
        }

        // Then
        let successResponse = try XCTUnwrap(result.get())
        XCTAssertTrue(successResponse)
    }

    func test_createPackage_returns_error_on_failure() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "shipping-label-create-package-error")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.createPackage(siteID: self.sampleSiteID,
                                 customPackage: ShippingLabelCustomPackage.fake(),
                                 predefinedOption: ShippingLabelPredefinedOption.fake()) { result in
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
        let remote = ShippingLabelRemote(network: network)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.createPackage(siteID: self.sampleSiteID,
                                 customPackage: nil,
                                 predefinedOption: nil) { result in
                promise(result)
            }
        }

        // Then
        let expectedError = ShippingLabelRemote.ShippingLabelError.missingPackage
        XCTAssertEqual(result.failure as? ShippingLabelRemote.ShippingLabelError, expectedError)
    }

    func test_loadCarriersAndRates_parses_success_response() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(sampleOrderID)/rates", filename: "shipping-label-carriers-and-rates-success")
        let expectedDefaultRate = sampleShippingLabelCarrierRate()

        // When
        let result: Result<[ShippingLabelCarriersAndRates], Error> = waitFor { promise in
            remote.loadCarriersAndRates(siteID: self.sampleSiteID,
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

    func test_loadCarriersAndRates_returns_error_on_failure() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(sampleOrderID)/rates", filename: "generic_error")

        // When
        let result: Result<ShippingLabelAccountSettings, Error> = waitFor { promise in
            remote.loadShippingLabelAccountSettings(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_loadShippingLabelAccountSettings_returns_settings_on_success() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "account/settings", filename: "shipping-label-account-settings")

        // When
        let result: Result<ShippingLabelAccountSettings, Error> = waitFor { promise in
            remote.loadShippingLabelAccountSettings(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(try result.get())
    }

    func test_loadShippingLabelAccountSettings_returns_error_on_failure() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "account/settings", filename: "generic_error")

        // When
        let result: Result<ShippingLabelAccountSettings, Error> = waitFor { promise in
            remote.loadShippingLabelAccountSettings(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_updateShippingLabelAccountSettings_returns_true_on_success() throws {
        // Given
        let settings = ShippingLabelAccountSettings.fake().copy()
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "account/settings", filename: "generic_success_data")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.updateShippingLabelAccountSettings(siteID: self.sampleSiteID, settings: settings) { result in
                promise(result)
            }
        }

        // Then
        let response = try result.get()
        XCTAssertTrue(response)
    }

    func test_updateShippingLabelAccountSettings_returns_error_on_failure() throws {
        // Given
        let settings = ShippingLabelAccountSettings.fake().copy()
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "account/settings", filename: "generic_error")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.updateShippingLabelAccountSettings(siteID: self.sampleSiteID, settings: settings) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_checkCreationEligibility_returns_true_on_success() throws {
        // Given
        let orderID: Int64 = 321
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(orderID)/creation_eligibility", filename: "shipping-label-eligibility-success")

        // When
        let result: Result<ShippingLabelCreationEligibilityResponse, Error> = waitFor { promise in
            remote.checkCreationEligibility(siteID: self.sampleSiteID,
                                            orderID: orderID) { result in
                promise(result)
            }
        }

        // Then
        let response = try XCTUnwrap(result.get())
        XCTAssertEqual(response.isEligible, true)
    }

    func test_checkCreationEligibility_returns_reason_on_failure() throws {
        // Given
        let orderID: Int64 = 321
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(orderID)/creation_eligibility", filename: "shipping-label-eligibility-failure")

        // When
        let result: Result<ShippingLabelCreationEligibilityResponse, Error> = waitFor { promise in
            remote.checkCreationEligibility(siteID: self.sampleSiteID,
                                            orderID: orderID) { result in
                promise(result)
            }
        }

        // Then
        let response = try XCTUnwrap(result.get())
        XCTAssertEqual(response.isEligible, false)
        XCTAssertEqual(response.reason, "no_selected_payment_method_and_user_cannot_manage_payment_methods")
    }

    func test_purchaseShippingLabel_parses_success_response() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(sampleOrderID)", filename: "shipping-label-purchase-success")
        let expectedLabelPurchase = sampleShippingLabelPurchase()

        // When
        let result: Result<[ShippingLabelPurchase], Error> = waitFor { promise in
            remote.purchaseShippingLabel(siteID: self.sampleSiteID,
                                         orderID: self.sampleOrderID,
                                         originAddress: ShippingLabelAddress.fake(),
                                         destinationAddress: ShippingLabelAddress.fake(),
                                         packages: [ShippingLabelPackagePurchase.fake()],
                                         emailCustomerReceipt: true) { (result) in
                promise(result)
            }
        }

        // Then
        let successResponse = try XCTUnwrap(result.get())
        XCTAssertEqual(successResponse.first, expectedLabelPurchase)
    }

    func test_purchaseShippingLabel_returns_error_on_failure() throws {
        // Given
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(sampleOrderID)", filename: "generic_error")

        // When
        let result: Result<[ShippingLabelPurchase], Error> = waitFor { promise in
            remote.purchaseShippingLabel(siteID: self.sampleSiteID,
                                         orderID: self.sampleOrderID,
                                         originAddress: ShippingLabelAddress.fake(),
                                         destinationAddress: ShippingLabelAddress.fake(),
                                         packages: [ShippingLabelPackagePurchase.fake()],
                                         emailCustomerReceipt: true) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_checkLabelStatus_parses_success_response() throws {
        // Given
        let sampleLabelID: Int64 = 4321
        let expectedLabelStatus = ShippingLabel.fake().status
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(sampleOrderID)/\(sampleLabelID)", filename: "shipping-label-status-success")

        // When
        let result: Result<[ShippingLabelStatusPollingResponse], Error> = waitFor { promise in
            remote.checkLabelStatus(siteID: self.sampleSiteID,
                                    orderID: self.sampleOrderID,
                                    labelIDs: [sampleLabelID]) { (result) in
                promise(result)
            }
        }

        // Then
        let successResponse = try XCTUnwrap(result.get())
        let shippingLabel = successResponse.first
        XCTAssertEqual(shippingLabel?.status, expectedLabelStatus)
    }

    func test_checkLabelStatus_returns_error_on_failure() throws {
        // Given
        let sampleLabelID: Int64 = 4321
        let remote = ShippingLabelRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/\(sampleOrderID)/\(sampleLabelID)", filename: "generic_error")

        // When
        let result: Result<[ShippingLabelStatusPollingResponse], Error> = waitFor { promise in
            remote.checkLabelStatus(siteID: self.sampleSiteID,
                                    orderID: self.sampleOrderID,
                                    labelIDs: [sampleLabelID]) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }
}

private extension ShippingLabelRemoteTests {
    func sampleShippingLabelAddressVerification() -> ShippingLabelAddressVerification {
        let type: ShippingLabelAddressVerification.ShipType = .destination
        return ShippingLabelAddressVerification(address: sampleShippingLabelAddress(), type: type)
    }

    func sampleShippingLabelAddressWithoutNameVerification() -> ShippingLabelAddressVerification {
        let type: ShippingLabelAddressVerification.ShipType = .destination
        return ShippingLabelAddressVerification(address: sampleShippingLabelAddressWithoutName(), type: type)
    }

    func sampleShippingLabelAddress() -> ShippingLabelAddress {
        return ShippingLabelAddress(company: "",
                                    name: "Anitaa",
                                    phone: "41535032",
                                    country: "US",
                                    state: "CA",
                                    address1: "60 29TH ST # 343",
                                    address2: "",
                                    city: "SAN FRANCISCO",
                                    postcode: "94110-4929")
    }

    func sampleShippingLabelAddressWithoutName() -> ShippingLabelAddress {
        return ShippingLabelAddress(company: "Automattic",
                                    name: "",
                                    phone: "41535032",
                                    country: "US",
                                    state: "CA",
                                    address1: "60 29TH ST # 343",
                                    address2: "",
                                    city: "SAN FRANCISCO",
                                    postcode: "94110-4929")
    }

    func sampleShippingLabelCarrierRate() -> ShippingLabelCarrierRate {
        let rate = ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                            insurance: "0",
                                            retailRate: 40.060000000000002,
                                            rate: 40.060000000000002,
                                            rateID: "rate_a8a29d5f34984722942f466c30ea27ef",
                                            serviceID: "ParcelSelect",
                                            carrierID: "usps",
                                            shipmentID: "shp_e0e3c2f4606c4b198d0cbd6294baed56",
                                            hasTracking: true,
                                            isSelected: false,
                                            isPickupFree: true,
                                            deliveryDays: 2,
                                            deliveryDateGuaranteed: false)

        return rate
    }

    func sampleShippingLabelPurchase() -> ShippingLabelPurchase {
        return ShippingLabelPurchase(siteID: sampleSiteID,
                                     orderID: sampleOrderID,
                                     shippingLabelID: 733,
                                     carrierID: nil,
                                     dateCreated: Date(timeIntervalSince1970: 1584549793.938),
                                     packageName: "Test",
                                     trackingNumber: nil,
                                     serviceName: "USPS - First Class Mail",
                                     refundableAmount: 0,
                                     status: ShippingLabelStatus.purchaseInProgress,
                                     productIDs: [],
                                     productNames: ["Beanie"])
    }
}
