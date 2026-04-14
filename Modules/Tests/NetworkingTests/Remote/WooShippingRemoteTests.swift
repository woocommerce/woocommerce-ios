import XCTest
import TestKit
@testable import Networking
@testable import NetworkingCore

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

    func test_checkCreationEligibility_returns_true_on_success() throws {
        // Given
        let orderID: Int64 = 321
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "eligibility/\(orderID)", filename: "shipping-label-eligibility-success")

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
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "eligibility/\(orderID)", filename: "shipping-label-eligibility-failure")

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
        XCTAssertEqual(packagesResponse.customPackages.count, 2)
        XCTAssertEqual(packagesResponse.customPackages.first?.id, "69d7052f934a7c218329de9c1abe3858")
        XCTAssertEqual(packagesResponse.customPackages.first?.name, "WCS&T Box")
        XCTAssertEqual(packagesResponse.customPackages.first?.dimensions, "15 x 15 x 15")
        XCTAssertEqual(packagesResponse.customPackages.first?.type, .box)
        XCTAssertEqual(packagesResponse.customPackages.first?.boxWeight, 0.25)
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
                     message: "At least one of the new custom packages has the same name as existing packages.",
                     data: nil)
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

    func test_deletePackage_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        let package = WooShippingCustomPackage.fake()
        network.simulateResponse(requestUrlSuffix: "packages/custom/\(package.id)", filename: "wooshipping-delete-package-success")

        // When
        let result: Result<WooShippingCreatePackageResponse, Error> = waitFor { promise in
            remote.deletePackage(siteID: self.sampleSiteID,
                                 packageID: package.id,
                                 packageType: .custom) { result in
                promise(result)
            }
        }

        // Then
        let packagesResponse = try XCTUnwrap(result.get())
        XCTAssertEqual(packagesResponse.customPackages.count, 5)
        XCTAssertEqual(packagesResponse.predefinedOptions.count, 1)
    }

    func test_deletePackage_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        let package = WooShippingCustomPackage.fake()
        network.simulateResponse(requestUrlSuffix: "packages/custom/\(package.id)", filename: "generic_error")

        // When
        let result: Result<WooShippingCreatePackageResponse, Error> = waitFor { promise in
            remote.deletePackage(siteID: self.sampleSiteID,
                                 packageID: package.id,
                                 packageType: .custom) { result in
                promise(result)
            }
        }

        // Then
        let expectedError = DotcomError.unauthorized()
        XCTAssertEqual(result.failure as? DotcomError, expectedError)
    }

    func test_loadLabelRates_sends_correct_params_and_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/rate", filename: "wooshipping-get-label-rates-success")
        let expectedDefaultRate = sampleLabelRate()
        let expectedPackage = ShippingLabelPackageSelected.fake().copy(length: 12, width: 20, height: 0)

        // When
        let result: Result<[ShippingLabelCarriersAndRates], Error> = waitFor { promise in
            remote.loadLabelRates(siteID: self.sampleSiteID,
                                  orderID: self.sampleOrderID,
                                  originAddress: WooShippingAddress.fake(),
                                  destinationAddress: WooShippingAddress.fake(),
                                  packages: [expectedPackage]) { (result) in
                promise(result)
            }
        }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let featuresParam = try XCTUnwrap(request.parameters["features_supported_by_client"] as? [String])
        XCTAssertEqual(featuresParam, ["upsdap"])
        let packagesParam = try XCTUnwrap(request.parameters["packages"] as? [[String: Any]])
        let package = try XCTUnwrap(packagesParam.first)
        XCTAssertEqual(package["height"] as? Double, 0.25)

        let successResponse = try XCTUnwrap(result.get())
        XCTAssertEqual(successResponse.first?.defaultRates.first, expectedDefaultRate)
        XCTAssertEqual(successResponse.first?.carbonNeutral.count, 1)
        XCTAssertEqual(successResponse.first?.saturdayDelivery.count, 1)
        XCTAssertEqual(successResponse.first?.additionalHandling.count, 2)
    }

    func test_loadLabelRates_parses_invalid_destination_name_rate_error() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/rate",
                                 filename: "wooshipping-get-label-rates-invalid-destination-name")

        // When
        let result: Result<[ShippingLabelCarriersAndRates], Error> = waitFor { promise in
            remote.loadLabelRates(siteID: self.sampleSiteID,
                                  orderID: self.sampleOrderID,
                                  originAddress: WooShippingAddress.fake(),
                                  destinationAddress: WooShippingAddress.fake(),
                                  packages: [ShippingLabelPackageSelected.fake()]) { result in
                promise(result)
            }
        }

        // Then
        let response = try XCTUnwrap(result.get())
        XCTAssertEqual(response.first?.defaultErrors.first?.code, "rate_error")
        XCTAssertEqual(response.first?.defaultErrors.first?.message,
                       "shipment.to_address: invalid name; A first and last name is required if passed in: input name needs at least 1 space character")
    }

    func test_loadLabelRates_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/rate", filename: "generic_error")

        // When
        let result: Result<[ShippingLabelCarriersAndRates], Error> = waitFor { promise in
            remote.loadLabelRates(siteID: self.sampleSiteID,
                                  orderID: self.sampleOrderID,
                                  originAddress: WooShippingAddress.fake(),
                                  destinationAddress: WooShippingAddress.fake(),
                                  packages: [ShippingLabelPackageSelected.fake()]) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_loadPackages_sends_correct_params_and_parses_success_response() throws {
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
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let featuresParam = try XCTUnwrap(request.parameters["features_supported_by_client"] as? [String])
        XCTAssertEqual(featuresParam, ["upsdap"])

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
        let result: Result<WooShippingAccountSettings, Error> = waitFor { promise in
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
        XCTAssertEqual(successResponse.accountSettings.storeOwnerDisplayName, "John Smith")
        XCTAssertEqual(successResponse.accountSettings.storeOwnerUsername, "jsmith")
        XCTAssertEqual(successResponse.accountSettings.storeOwnerWpcomUsername, "jsmith")
        XCTAssertEqual(successResponse.accountSettings.storeOwnerWpcomEmail, "jsmith@example.com")

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

    func test_updateAccountSettings_sends_correct_values_and_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "account/settings", filename: "generic_success")

        // When
        let settings = ShippingLabelAccountSettings.fake().copy(selectedPaymentMethodID: 123,
                                                                isEmailReceiptsEnabled: false)
        let result: Result<Bool, Error> = waitFor { promise in
            remote.updateAccountSettings(siteID: self.sampleSiteID, settings: settings) { result in
                promise(result)
            }
        }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let paymentMethodID = try XCTUnwrap(request.parameters["selected_payment_method_id"] as? Int64)
        let isEmailReceiptsEnabled = try XCTUnwrap(request.parameters["email_receipts"] as? Bool)
        XCTAssertEqual(paymentMethodID, 123)
        XCTAssertFalse(isEmailReceiptsEnabled)
        XCTAssertTrue(try result.get())
    }

    func test_loadAccountSettings_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "account/settings", filename: "generic_error")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.updateAccountSettings(siteID: self.sampleSiteID, settings: .fake()) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_updateAccountSettings_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "account/settings", filename: "generic_error")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.updateAccountSettings(siteID: self.sampleSiteID, settings: .fake()) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_purchaseShippingLabel_sends_correct_parameters() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/purchase/\(sampleOrderID)", filename: "wooshipping-purchase-success")

        let shipmentID = "1"
        let hazmatCategory = "test-hazmat"
        let customsForm = ShippingLabelCustomsForm(packageID: "test",
                                                   packageName: "ups-test",
                                                   contentsType: .merchandise,
                                                   contentExplanation: "",
                                                   restrictionType: .none,
                                                   restrictionComments: "",
                                                   nonDeliveryOption: .return,
                                                   itn: "",
                                                   items: [.fake(), .fake()])

        let package = WooShippingPackagePurchase.fake().copy(
            shipmentID: shipmentID,
            package: ShippingLabelPackageSelected.fake().copy(
                height: 0,
                hazmatCategory: hazmatCategory,
                customsForm: customsForm
            ),
            selectedRate: WooShippingSelectedRate(
                rate: ShippingLabelCarrierRate.fake().copy(rate: 12.32),
                adultSignatureRate: ShippingLabelCarrierRate.fake().copy(rate: 22.33),
                carbonNeutralRate: ShippingLabelCarrierRate.fake().copy(rate: 18.02),
                saturdayDeliveryRate: ShippingLabelCarrierRate.fake().copy(rate: 25.42),
                additionalHandlingRate: ShippingLabelCarrierRate.fake().copy(rate: 20.01)
            )
        )
        let markOrderComplete = true

        let originEmail = "origin@example.com"
        let destinationEmail = "destination@example.com"

        // When
        let result: Result<[ShippingLabelPurchase], Error> = waitFor { promise in
            remote.purchaseShippingLabel(siteID: self.sampleSiteID,
                                         orderID: self.sampleOrderID,
                                         originAddress: WooShippingAddress.fake().copy(email: originEmail),
                                         destinationAddress: WooShippingAddress.fake().copy(email: destinationEmail),
                                         package: package,
                                         markOrderComplete: markOrderComplete) { result in
                promise(result)
            }
        }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)

        let selectedRateOptions = try XCTUnwrap(request.parameters["selected_rate_options"] as? [String: Any])
        let signatureObject = try XCTUnwrap(selectedRateOptions["signature"] as? [String: Any])
        XCTAssertEqual(signatureObject["value"] as? String, "adult")
        XCTAssertEqual(signatureObject["surcharge"] as? Double, package.selectedRate.surchargeForAdultSignatureRequirement)

        let carbonNeutralObject = try XCTUnwrap(selectedRateOptions["carbon_neutral"] as? [String: Any])
        XCTAssertEqual(carbonNeutralObject["value"] as? Bool, true)
        XCTAssertEqual(carbonNeutralObject["surcharge"] as? Double, package.selectedRate.surchargeForCarbonNeutralRate)

        let saturdayDeliveryObject = try XCTUnwrap(selectedRateOptions["saturday_delivery"] as? [String: Any])
        XCTAssertEqual(saturdayDeliveryObject["value"] as? Bool, true)
        XCTAssertEqual(saturdayDeliveryObject["surcharge"] as? Double, package.selectedRate.surchargeForSaturdayDeliveryRate)

        let additionalHandlingObject = try XCTUnwrap(selectedRateOptions["additional_handling"] as? [String: Any])
        XCTAssertEqual(additionalHandlingObject["value"] as? Bool, true)
        XCTAssertEqual(additionalHandlingObject["surcharge"] as? Double, package.selectedRate.surchargeForAdditionalHandlingRate)

        let packagesParam = try XCTUnwrap(request.parameters["packages"] as? [[String: Any]])
        let firstPackage = try XCTUnwrap(packagesParam.first)
        XCTAssertEqual(firstPackage["height"] as? Double, 0.25)
        XCTAssertEqual(firstPackage["signature"] as? String, "adult")
        XCTAssertEqual(firstPackage["carbon_neutral"] as? Bool, true)
        XCTAssertEqual(firstPackage["saturday_delivery"] as? Bool, true)
        XCTAssertEqual(firstPackage["additional_handling"] as? Bool, true)
        XCTAssertEqual(firstPackage["hazmat"] as? String, hazmatCategory)

        /// customs form details need to be present in package
        XCTAssertEqual(try XCTUnwrap(firstPackage["items"] as? [Any]).count, 2)
        XCTAssertEqual(firstPackage["contents_type"] as? String, "merchandise")
        XCTAssertEqual(firstPackage["restriction_type"] as? String, "none")
        XCTAssertEqual(firstPackage["non_delivery_option"] as? String, "return")
        XCTAssertEqual(firstPackage["restriction_comments"] as? String, "")
        XCTAssertEqual(firstPackage["contents_explanation"] as? String, "")

        let originParam = try XCTUnwrap(request.parameters["origin"] as? [String: Any])
        XCTAssertEqual(originParam["email"] as? String, originEmail)

        let destinationParam = try XCTUnwrap(request.parameters["destination"] as? [String: Any])
        XCTAssertEqual(destinationParam["email"] as? String, destinationEmail)

        let selectedRateParam = try XCTUnwrap(request.parameters["selected_rate"] as? [String: Any])
        let parentValue = try XCTUnwrap(selectedRateParam["parent"] as? [String: Any])
        XCTAssertEqual(parentValue["rate"] as? Double, package.selectedRate.rate.rate)

        let childValue = try XCTUnwrap(selectedRateParam["rate"] as? [String: Any])
        XCTAssertEqual(childValue["rate"] as? Double, package.selectedRate.adultSignatureRate?.rate)
        XCTAssertEqual(childValue["type"] as? String, "adultSignatureRequired")

        let hazmatValue = try XCTUnwrap(request.parameters["hazmat"] as? [String: Any])
        let hazmatShipment = try XCTUnwrap(hazmatValue["shipment_" + shipmentID] as? [String: Any])
        XCTAssertEqual(hazmatShipment["category"] as? String, hazmatCategory)

        let customsValue = try XCTUnwrap(request.parameters["customs"] as? [String: Any])
        let customsShipment = try XCTUnwrap(customsValue["shipment_" + shipmentID] as? [String: Any])
        XCTAssertEqual((try XCTUnwrap(customsShipment["items"] as? [Any])).count, 2)

        let userMetaValue = try XCTUnwrap(request.parameters["user_meta"] as? [String: Any])
        XCTAssertEqual(userMetaValue["last_order_completed"] as? Bool, true)

        let labels = try XCTUnwrap(result.get())
        XCTAssertEqual(labels.count, 1)
    }

    func test_purchaseShippingLabel_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/purchase/\(sampleOrderID)", filename: "wooshipping-purchase-success")

        // When
        let result: Result<[ShippingLabelPurchase], Error> = waitFor { promise in
            remote.purchaseShippingLabel(siteID: self.sampleSiteID,
                                         orderID: self.sampleOrderID,
                                         originAddress: WooShippingAddress.fake(),
                                         destinationAddress: WooShippingAddress.fake(),
                                         package: WooShippingPackagePurchase.fake(),
                                         markOrderComplete: false) { result in
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
                                         originAddress: WooShippingAddress.fake(),
                                         destinationAddress: WooShippingAddress.fake(),
                                         package: WooShippingPackagePurchase.fake(),
                                         markOrderComplete: false) { result in
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
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/status/\(sampleOrderID)/\(sampleLabelID)", filename: "wooshipping-label-status-success")

        // When
        let result: Result<ShippingLabelStatusPollingResponse, Error> = waitFor { promise in
            remote.checkLabelStatus(siteID: self.sampleSiteID,
                                    orderID: self.sampleOrderID,
                                    labelID: sampleLabelID) { result in
                promise(result)
            }
        }

        // Then
        let label = try XCTUnwrap(result.get())
        XCTAssertEqual(label.status, expectedLabelStatus)
    }

    func test_checkLabelStatus_returns_error_on_failure() throws {
        // Given
        let sampleLabelID: Int64 = 4321
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/status/\(sampleOrderID)/\(sampleLabelID)", filename: "generic_error")

        // When
        let result: Result<ShippingLabelStatusPollingResponse, Error> = waitFor { promise in
            remote.checkLabelStatus(siteID: self.sampleSiteID,
                                    orderID: self.sampleOrderID,
                                    labelID: sampleLabelID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_printLabel_returns_ShippingLabelPrintData() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/print", filename: "wooshipping-label-print-success")

        // When
        let printData: ShippingLabelPrintData = waitFor { promise in
            remote.printLabel(siteID: self.sampleSiteID,
                              labelIDs: [4321],
                              paperSize: .label) { result in
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
        XCTAssertNotNil(printData.data)
    }

    func test_printLabel_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/print", filename: "generic_error")

        // When
        let result: Result<ShippingLabelPrintData, Error> = waitFor { promise in
            remote.printLabel(siteID: self.sampleSiteID,
                              labelIDs: [4321],
                              paperSize: .label) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_loadOriginAddresses_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "address/origins", filename: "wooshipping-get-origin-addresses-success")

        // When
        let result: Result<[WooShippingOriginAddress], Error> = waitFor { promise in
            remote.loadOriginAddresses(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let addresses = try XCTUnwrap(result.get())
        XCTAssertEqual(addresses.count, 1)
        XCTAssertEqual(addresses.first, sampleOriginAddress())
    }

    func test_loadOriginAddresses_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "address/origins", filename: "generic_error")

        // When
        let result: Result<[WooShippingOriginAddress], Error> = waitFor { promise in
            remote.loadOriginAddresses(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_addressValidation_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "address/normalize", filename: "wooshipping-address-validation-success")

        // When
        let result: Result<WooShippingAddressValidationSuccess, Error> = waitFor { promise in
            remote.addressValidation(siteID: self.sampleSiteID,
                                     address: WooShippingAddress.fake()) { result in
                promise(result)
            }
        }

        // Then
        let validationResponse = try XCTUnwrap(result.get())
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(validationResponse.normalizedAddress)
        XCTAssertNotNil(validationResponse.originalAddress)
        XCTAssertFalse(validationResponse.isTrivialNormalization)
    }

    func test_addressValidation_returns_errors_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "address/normalize", filename: "wooshipping-address-validation-error")

        // When
        let result: Result<WooShippingAddressValidationSuccess, Error> = waitFor { promise in
            remote.addressValidation(siteID: self.sampleSiteID,
                                     address: WooShippingAddress.fake()) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure as? WooShippingAddressValidationError)
        XCTAssertEqual(error.addressError, "House number is missing")
        XCTAssertEqual(error.generalError, "Address not found")
        XCTAssertEqual(error.nameError, "Either Name or Company is required")
    }

    func test_addressValidation_returns_error_on_network_failure() {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "address/normalize", filename: "generic_error")

        // When
        let result: Result<WooShippingAddressValidationSuccess, Error> = waitFor { promise in
            remote.addressValidation(siteID: self.sampleSiteID,
                                     address: WooShippingAddress.fake()) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_updateOriginAddress_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "address/update_origin", filename: "wooshipping-update-origin-success")

        // When
        let result: Result<WooShippingOriginAddressUpdate, Error> = waitFor { promise in
            remote.updateOriginAddress(siteID: self.sampleSiteID,
                                       address: WooShippingOriginAddress.fake(),
                                       isVerified: true) { result in
                promise(result)
            }
        }

        // Then
        let addressUpdate = try XCTUnwrap(result.get())
        XCTAssertEqual(addressUpdate.address, sampleOriginAddress())
        XCTAssertTrue(addressUpdate.isVerified)
    }

    func test_updateOriginAddress_returns_error_on_network_failure() {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "address/update_origin", filename: "generic_error")

        // When
        let result: Result<WooShippingOriginAddressUpdate, Error> = waitFor { promise in
            remote.updateOriginAddress(siteID: self.sampleSiteID,
                                       address: WooShippingOriginAddress.fake(),
                                       isVerified: true) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    // MARK: verifyDestinationAddress

    func test_verifyDestinationAddress_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "address/\(sampleOrderID)/verify_order", filename: "wooshipping-verify-destination-success")

        // When
        let result: Result<WooShippingVerifyDestinationAddressSuccess, Error> = waitFor { promise in
            remote.verifyDestinationAddress(siteID: self.sampleSiteID,
                                            orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        // Then
        let validationResponse = try XCTUnwrap(result.get())
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(validationResponse.normalizedAddress)
        let isTrivialNormalization = try XCTUnwrap(validationResponse.isTrivialNormalization)
        XCTAssertFalse(isTrivialNormalization)
    }

    func test_verifyDestinationAddress_returns_errors_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "address/\(sampleOrderID)/verify_order", filename: "wooshipping-verify-destination-error")

        // When
        let result: Result<WooShippingVerifyDestinationAddressSuccess, Error> = waitFor { promise in
            remote.verifyDestinationAddress(siteID: self.sampleSiteID,
                                            orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure as? WooShippingAddressValidationError)
        XCTAssertEqual(error.addressError, "House number is missing")
        XCTAssertEqual(error.generalError, "Address not found")
        XCTAssertEqual(error.nameError, "Either Name or Company is required")
    }

    func test_verifyDestinationAddress_returns_error_on_network_failure() {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "address/\(sampleOrderID)/verify_order", filename: "generic_error")

        // When
        let result: Result<WooShippingVerifyDestinationAddressSuccess, Error> = waitFor { promise in
            remote.verifyDestinationAddress(siteID: self.sampleSiteID,
                                            orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    // MARK: Update destination address

    func test_updateDestinationAddress_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "address/\(sampleOrderID)/update_destination", filename: "wooshipping-update-destination-success")

        // When
        let result: Result<WooShippingDestinationAddressUpdate, Error> = waitFor { promise in
            remote.updateDestinationAddress(siteID: self.sampleSiteID,
                                            orderID: self.sampleOrderID,
                                            address: WooShippingDestinationAddress.fake(),
                                            isVerified: true) { result in
                promise(result)
            }
        }

        // Then
        let addressUpdate = try XCTUnwrap(result.get())
        XCTAssertEqual(addressUpdate.address, sampleDestinationAddress())
        XCTAssertTrue(addressUpdate.isVerified)
    }

    func test_updateDestinationAddress_returns_error_on_network_failure() {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "address/\(sampleOrderID)/update_destination", filename: "generic_error")

        // When
        let result: Result<WooShippingDestinationAddressUpdate, Error> = waitFor { promise in
            remote.updateDestinationAddress(siteID: self.sampleSiteID,
                                            orderID: self.sampleOrderID,
                                            address: WooShippingDestinationAddress.fake(),
                                            isVerified: true) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    // MARK: Load config

    func test_loadConfig_sends_correct_fields_value() async throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "config/label-purchase/\(sampleOrderID)", filename: "shipping-label-config-success")

        // When
        _ = waitFor { promise in
            remote.loadConfig(siteID: self.sampleSiteID,
                              orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let fieldsValue = try XCTUnwrap(request.parameters["_fields"] as? String)
        XCTAssertEqual(WooShippingConfigMapper.fieldsToLoad, fieldsValue)
    }

    func test_loadConfig_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "config/label-purchase/\(sampleOrderID)", filename: "shipping-label-config-success")

        // When
        let result: Result<WooShippingConfig, Error> = waitFor { promise in
            remote.loadConfig(siteID: self.sampleSiteID,
                              orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        // Then
        let config = try XCTUnwrap(result.get())
        XCTAssertEqual(config.shipments.count, 3)
    }

    func test_loadConfig_returns_error_on_network_failure() {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "config/label-purchase/\(sampleOrderID)", filename: "generic_error")

        // When
        let result: Result<WooShippingConfig, Error> = waitFor { promise in
            remote.loadConfig(siteID: self.sampleSiteID,
                              orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    // MARK: - Load Config With Destinations

    func test_load_config_with_addresses_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "config/label-purchase/\(sampleOrderID)", filename: "wooshipping-config-with-addresses")

        // When
        let result: Result<WooShippingConfig, Error> = waitFor { promise in
            remote.loadConfig(siteID: self.sampleSiteID, orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        // Then
        let config = try XCTUnwrap(result.get())
        let label = try XCTUnwrap(config.shippingLabelData?.currentOrderLabels.first)
        XCTAssertNotNil(label.destinationAddress)
        XCTAssertEqual(label.destinationAddress.address1, "200 N SPRING ST")
        XCTAssertNotNil(label.originAddress)
        XCTAssertEqual(label.originAddress.address1, "Test origin address line")
    }

    func test_load_config_without_addresses_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "config/label-purchase/\(sampleOrderID)", filename: "wooshipping-config-without-addresses")

        // When
        let result: Result<WooShippingConfig, Error> = waitFor { promise in
            remote.loadConfig(siteID: self.sampleSiteID, orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        // Then
        let config = try XCTUnwrap(result.get())
        let label = try XCTUnwrap(config.shippingLabelData?.currentOrderLabels.first)
        XCTAssertTrue(label.destinationAddress.isEmpty)
        XCTAssertTrue(label.originAddress.isEmpty)
    }

    func test_load_config_with_invalid_addresses_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "config/label-purchase/\(sampleOrderID)", filename: "wooshipping-config-with-invalid-addresses")

        // When
        let result: Result<WooShippingConfig, Error> = waitFor { promise in
            remote.loadConfig(siteID: self.sampleSiteID, orderID: self.sampleOrderID) { result in
                promise(result)
            }
        }

        // Then
        let config = try XCTUnwrap(result.get())
        let label = try XCTUnwrap(config.shippingLabelData?.currentOrderLabels.first)
        XCTAssertTrue(label.destinationAddress.isEmpty)
        XCTAssertTrue(label.originAddress.isEmpty)
    }

    // MARK: Update shipment

    func test_updateShipment_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "shipments/\(sampleOrderID)", filename: "shipping-label-update-shipment")

        // When
        let result: Result<WooShippingShipments, Error> = waitFor { promise in
            remote.updateShipment(siteID: self.sampleSiteID,
                                  orderID: self.sampleOrderID,
                                  shipmentToUpdate: WooShippingUpdateShipment.fake()) { result in
                promise(result)
            }
        }

        // Then
        let shipments = try XCTUnwrap(result.get())
        XCTAssertEqual(shipments.count, 3)
    }

    func test_updateShipment_returns_error_on_network_failure() {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "shipments/\(sampleOrderID)", filename: "generic_error")

        // When
        let result: Result<WooShippingShipments, Error> = waitFor { promise in
            remote.updateShipment(siteID: self.sampleSiteID,
                                  orderID: self.sampleOrderID,
                                  shipmentToUpdate: WooShippingUpdateShipment.fake()) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    // MARK: Refund shipping label

    func test_refundShippingLabel_parses_success_response() throws {
        // Given
        let labelID: Int64 = 332
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/refund/\(sampleOrderID)/\(labelID)", filename: "wooshipping-label-refund-success")

        // When
        let result: Result<ShippingLabelRefund, Error> = waitFor { promise in
            remote.refundShippingLabel(siteID: self.sampleSiteID,
                                       orderID: self.sampleOrderID,
                                       shippingLabelID: labelID) { result in
                promise(result)
            }
        }

        // Then
        let refund = try XCTUnwrap(result.get())
        XCTAssertEqual(refund, ShippingLabelRefund(dateRequested: Date(timeIntervalSince1970: 1723147248.000), status: .pending))
    }

    func test_refundShippingLabel_returns_error_on_failure() throws {
        // Given
        let labelID: Int64 = 332
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "label/refund/\(sampleOrderID)/\(labelID)", filename: "wooshipping-label-refund-error")

        // When
        let result: Result<ShippingLabelRefund, Error> = waitFor { promise in
            remote.refundShippingLabel(siteID: self.sampleSiteID,
                                       orderID: self.sampleOrderID,
                                       shippingLabelID: labelID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    // MARK: Accept UPS TOS

    func test_acceptUPSTermsOfService_parses_success_response() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "carrier-strategy/upsdap", filename: "generic_success_data")

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.acceptUPSTermsOfService(siteID: self.sampleSiteID,
                                           originAddress: WooShippingAddress.fake()) { result in
                promise(result)
            }
        }

        // Then
        let success = try XCTUnwrap(result.get())
        XCTAssertTrue(success)
    }

    func test_acceptUPSTermsOfService_returns_error_on_failure() throws {
        // Given
        let remote = WooShippingRemote(network: network)
        let expectedError = NetworkError.timeout(response: nil)
        network.simulateError(requestUrlSuffix: "carrier-strategy/upsdap", error: expectedError)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            remote.acceptUPSTermsOfService(siteID: self.sampleSiteID,
                                           originAddress: WooShippingAddress.fake()) { result in
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

    func sampleOriginAddress() -> WooShippingOriginAddress {
        WooShippingOriginAddress(siteID: sampleSiteID,
                                 id: "store_details",
                                 company: "Superlative Centaur",
                                 address1: "60 29TH ST PMB 343",
                                 address2: "",
                                 city: "SAN FRANCISCO",
                                 state: "CA",
                                 postcode: "94110-4929",
                                 country: "US",
                                 phone: "12345678901",
                                 firstName: "First",
                                 lastName: "Last",
                                 email: "email@automattic.com",
                                 defaultAddress: true,
                                 isVerified: true)
    }

    func sampleDestinationAddress() -> WooShippingDestinationAddress {
        WooShippingDestinationAddress(company: "ACME Corp",
                                      address1: "789 Oak St",
                                      address2: "Suite 100",
                                      city: "Sometown",
                                      state: "TX",
                                      postcode: "54321",
                                      country: "US",
                                      phone: "555-0123",
                                      name: "",
                                      firstName: "John",
                                      lastName: "Smith",
                                      email: "john@example.com")
    }
}
