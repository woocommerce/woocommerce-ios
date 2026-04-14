import XCTest
import YosemiteTestHelpers
@testable import Yosemite
@testable import Networking
import protocol Storage.StorageType
import class Storage.ShippingLabelPaymentMethod

final class WooShippingStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    private var viewStorage: StorageType {
        storageManager.viewStorage
    }

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Testing Order ID
    ///
    private let sampleOrderID: Int64 = 12

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: `checkCreationEligibility`

    func test_checkCreationEligibility_returns_eligibility_on_success() throws {
        // Given
        let remote = MockWooShippingRemote()
        let orderID: Int64 = 22
        let expectedEligibility = true
        remote.whenCheckEligibility(siteID: sampleSiteID,
                                    orderID: orderID,
                                    thenReturn: .success(ShippingLabelCreationEligibilityResponse(isEligible: expectedEligibility, reason: nil)))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let isEligibleForCreation: Bool = waitFor { promise in
            let action = WooShippingAction.checkCreationEligibility(siteID: self.sampleSiteID,
                                                                    orderID: orderID) { isEligible in
                promise(isEligible)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(isEligibleForCreation, expectedEligibility)
    }

    func test_checkCreationEligibility_returns_false_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let orderID: Int64 = 22
        let expectedEligibility = false
        remote.whenCheckEligibility(siteID: sampleSiteID,
                                    orderID: orderID,
                                    thenReturn: .failure(NetworkError.notFound()))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let isEligibleForCreation: Bool = waitFor { promise in
            let action = WooShippingAction.checkCreationEligibility(siteID: self.sampleSiteID,
                                                                      orderID: orderID) { isEligible in
                promise(isEligible)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(isEligibleForCreation, expectedEligibility)
    }

    // MARK: `createPackage`

    func test_createPackage_returns_success_response() throws {
        // Given
        let remote = MockWooShippingRemote()
        let response = WooShippingCreatePackageResponse.fake().copy(customPackages: [WooShippingCustomPackage.fake()])
        remote.whenCreatePackage(siteID: sampleSiteID, thenReturn: .success(response))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingCreatePackageResponse, PackageCreationError> = waitFor { promise in
            let action = WooShippingAction.createPackage(siteID: self.sampleSiteID,
                                                         customPackage: WooShippingCustomPackage.fake(),
                                                         predefinedOption: nil) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let actualResponse = try result.get()
        XCTAssertEqual(actualResponse, response)
    }

    func test_createPackage_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let error = PackageCreationError.duplicateCustomPackageNames
        remote.whenCreatePackage(siteID: sampleSiteID, thenReturn: .failure(error))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingCreatePackageResponse, PackageCreationError> = waitFor { promise in
            let action = WooShippingAction.createPackage(siteID: self.sampleSiteID,
                                                         customPackage: WooShippingCustomPackage.fake(),
                                                         predefinedOption: nil) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    func test_createPackage_when_successful_then_upserts_packages_into_storage() throws {
        // Given
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "wooshipping-create-package-success")
        storageManager.insertSamplePackages(readOnlyPackages: .init(siteID: sampleSiteID,
                                                                    customPackages: [],
                                                                    savedPredefinedPackages: [],
                                                                    allPredefinedOptions: [sampleCarrierPredefinedOptions()]))

        // Confidence check
        XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: StorageWooShippingCustomPackage.self), 0)
        XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: StorageWooShippingSavedPredefinedPackage.self), 0)

        // When
        let onSuccess: Bool = waitFor { promise in
            let action = WooShippingAction.createPackage(siteID: self.sampleSiteID,
                                                         customPackage: .fake(),
                                                         predefinedOption: .fake()) { result in
                promise(result.isSuccess)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(onSuccess)
        let storedPackages = try XCTUnwrap(storageManager.viewStorage.firstObject(ofType: StorageWooShippingPackagesResponse.self)).toReadOnly()
        XCTAssertEqual(storedPackages.siteID, sampleSiteID)
        XCTAssertEqual(storedPackages.customPackages.count, 2)
        XCTAssertEqual(storedPackages.customPackages.first?.boxWeight, 0.25)
        XCTAssertEqual(storedPackages.customPackages.last?.boxWeight, 0.25)
        XCTAssertEqual(storedPackages.savedPredefinedPackages.count, 2)
    }

    // MARK: `deletePackage`

    func test_deletePackage_returns_success_response() throws {
        // Given
        let remote = MockWooShippingRemote()
        let response = WooShippingCreatePackageResponse.fake().copy(customPackages: [WooShippingCustomPackage.fake()])
        remote.whenDeletePackage(siteID: sampleSiteID, thenReturn: .success(response))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingCreatePackageResponse, Error> = waitFor { promise in
            let action = WooShippingAction.deletePackage(siteID: self.sampleSiteID,
                                                         packageID: WooShippingCustomPackage.fake().id,
                                                         packageType: .custom) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let actualResponse = try result.get()
        XCTAssertEqual(actualResponse, response)
    }

    func test_deletePackage_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let error = DotcomError.requestFailed()
        remote.whenDeletePackage(siteID: sampleSiteID, thenReturn: .failure(error))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingCreatePackageResponse, Error> = waitFor { promise in
            let action = WooShippingAction.deletePackage(siteID: self.sampleSiteID,
                                                         packageID: WooShippingCustomPackage.fake().id,
                                                         packageType: .custom) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    func test_deletePackage_when_successful_then_upserts_packages_into_storage() throws {
        // Given
        let remote = MockWooShippingRemote()
        let response = WooShippingCreatePackageResponse.fake().copy(customPackages: [WooShippingCustomPackage.fake().copy(id: "2")],
                                                                    predefinedOptions: [.init(id: "usps", predefinedPackageIDs: ["small_flat_box"])])
        remote.whenDeletePackage(siteID: sampleSiteID, thenReturn: .success(response))
        storageManager.insertSamplePackages(readOnlyPackages: .init(siteID: sampleSiteID,
                                                                    customPackages: [WooShippingCustomPackage.fake().copy(id: "1"),
                                                                                     WooShippingCustomPackage.fake().copy(id: "2")],
                                                                    savedPredefinedPackages: [.init(groupTitle: "pri_flat_boxes",
                                                                                                    providerID: "usps",
                                                                                                    package: .init(id: "small_flat_box",
                                                                                                                   name: "",
                                                                                                                   isLetter: false,
                                                                                                                   dimensions: "",
                                                                                                                   boxWeight: "",
                                                                                                                   groupId: "")),
                                                                                              .init(groupTitle: "pri_flat_boxes",
                                                                                                    providerID: "usps",
                                                                                                    package: .init(id: "medium_flat_box_top",
                                                                                                                   name: "",
                                                                                                                   isLetter: false,
                                                                                                                   dimensions: "",
                                                                                                                   boxWeight: "",
                                                                                                                   groupId: ""))],
                                                                    allPredefinedOptions: [sampleCarrierPredefinedOptions()]))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let onSuccess: Bool = waitFor { promise in
            let action = WooShippingAction.deletePackage(siteID: self.sampleSiteID,
                                                         packageID: WooShippingCustomPackage.fake().id,
                                                         packageType: .custom) { result in
                promise(result.isSuccess)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(onSuccess)
        let storedPackages = try XCTUnwrap(storageManager.viewStorage.firstObject(ofType: StorageWooShippingPackagesResponse.self)).toReadOnly()
        XCTAssertEqual(storedPackages.siteID, sampleSiteID)
        XCTAssertEqual(storedPackages.customPackages.count, 1)
        XCTAssertEqual(storedPackages.savedPredefinedPackages.count, 1)
    }

    // MARK: `loadLabelRates`

    func test_loadLabelRates_returns_success_response_with_rates() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedRates = sampleLabelRates()
        remote.whenLoadLabelRates(siteID: sampleSiteID, thenReturn: .success(expectedRates))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<[ShippingLabelCarriersAndRates], Error> = waitFor { promise in
            let action = WooShippingAction.loadLabelRates(siteID: self.sampleSiteID,
                                                          orderID: self.sampleOrderID,
                                                          originAddress: WooShippingAddress.fake(),
                                                          destinationAddress: WooShippingAddress.fake(),
                                                          packages: [ShippingLabelPackageSelected.fake()]) { _, result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let rates = (try result.get())
        XCTAssertEqual(rates, expectedRates)
    }

    func test_loadLabelRates_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedError = NetworkError.notFound()
        remote.whenLoadLabelRates(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<[ShippingLabelCarriersAndRates], Error> = waitFor { promise in
            let action = WooShippingAction.loadLabelRates(siteID: self.sampleSiteID,
                                                          orderID: self.sampleOrderID,
                                                          originAddress: WooShippingAddress.fake(),
                                                          destinationAddress: WooShippingAddress.fake(),
                                                          packages: [ShippingLabelPackageSelected.fake()]) { _, result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    func test_loadLabelRates_maps_invalid_destination_name_rate_error() throws {
        // Given
        let remote = MockWooShippingRemote()
        let ratesWithError = [ShippingLabelCarriersAndRates(packageID: "123",
                                                            defaultRates: [],
                                                            defaultErrors: [ShippingLabelRateError(code: "rate_error",
                                                                                                  message: "shipment.to_address: invalid name; A first and last name is required if passed in: input name needs at least 1 space character")],
                                                            signatureRequired: [],
                                                            adultSignatureRequired: [],
                                                            carbonNeutral: [],
                                                            saturdayDelivery: [],
                                                            additionalHandling: [])]
        remote.whenLoadLabelRates(siteID: sampleSiteID, thenReturn: .success(ratesWithError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<[ShippingLabelCarriersAndRates], Error> = waitFor { promise in
            let action = WooShippingAction.loadLabelRates(siteID: self.sampleSiteID,
                                                          orderID: self.sampleOrderID,
                                                          originAddress: WooShippingAddress.fake(),
                                                          destinationAddress: WooShippingAddress.fake(),
                                                          packages: [ShippingLabelPackageSelected.fake()]) { _, result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertNotNil(result.failure as? WooShippingLoadLabelRatesError)
    }

    func test_loadLabelRates_returns_sent_packages_on_success() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedRates = sampleLabelRates()
        remote.whenLoadLabelRates(siteID: sampleSiteID, thenReturn: .success(expectedRates))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        let samplePackage = ShippingLabelPackageSelected.fake().copy(id: "test_package",
                                                                     boxID: "test_box_id",
                                                                     length: 11,
                                                                     width: 12,
                                                                     height: 10)

        // When
        let receivedValue: [ShippingLabelPackageSelected] = waitFor { promise in
            let action = WooShippingAction.loadLabelRates(siteID: self.sampleSiteID,
                                                          orderID: self.sampleOrderID,
                                                          originAddress: WooShippingAddress.fake(),
                                                          destinationAddress: WooShippingAddress.fake(),
                                                          packages: [samplePackage]) { packages, _ in
                promise(packages)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(receivedValue, [samplePackage])
    }

    func test_loadLabelRates_returns_sent_packages_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedError = NetworkError.notFound()
        remote.whenLoadLabelRates(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        let samplePackage = ShippingLabelPackageSelected.fake().copy(id: "test_package",
                                                                     boxID: "test_box_id",
                                                                     length: 11,
                                                                     width: 12,
                                                                     height: 10)
        // When
        let receivedValue: [ShippingLabelPackageSelected] = waitFor { promise in
            let action = WooShippingAction.loadLabelRates(siteID: self.sampleSiteID,
                                                          orderID: self.sampleOrderID,
                                                          originAddress: WooShippingAddress.fake(),
                                                          destinationAddress: WooShippingAddress.fake(),
                                                          packages: [samplePackage]) { packages, _ in
                promise(packages)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(receivedValue, [samplePackage])
    }

    // MARK: `loadAccountSettings`

    func test_loadAccountSettings_returns_success_response() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedSettings = WooShippingAccountSettings.fake()
        remote.whenLoadAccountSettings(siteID: sampleSiteID, thenReturn: .success(expectedSettings))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingAccountSettings, Error> = waitFor { promise in
            let action = WooShippingAction.loadAccountSettings(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let actualSettings = try result.get()
        XCTAssertEqual(actualSettings, expectedSettings)
    }

    func test_loadAccountSettings_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedError = NetworkError.notFound()
        remote.whenLoadAccountSettings(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingAccountSettings, Error> = waitFor { promise in
            let action = WooShippingAction.loadAccountSettings(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    func test_loadAccountSettings_when_successful_then_upserts_settings_into_storage() throws {
        // Given
        let remote = MockWooShippingRemote()
        let paymentMethod = Yosemite.ShippingLabelPaymentMethod(
            paymentMethodID: 1434,
            name: "James Dean",
            cardType: .visa,
            cardDigits: "2352",
            expiry: DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2030-12-31")
        )
        let accountSettings = ShippingLabelAccountSettings.fake().copy(
            siteID: sampleSiteID,
            paymentMethods: [paymentMethod],
            isEmailReceiptsEnabled: true,
            paperSize: .a4
        )
        let expectedSettings = WooShippingAccountSettings.fake().copy(accountSettings: accountSettings)
        remote.whenLoadAccountSettings(siteID: sampleSiteID, thenReturn: .success(expectedSettings))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Confidence check
        XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: StorageShippingLabelAccountSettings.self), 0)

        // When
        let onSuccess: Bool = waitFor { promise in
            let action = WooShippingAction.loadAccountSettings(siteID: self.sampleSiteID) { result in
                promise(result.isSuccess)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(onSuccess)
        XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: StorageShippingLabelAccountSettings.self), 1)
        let storedSettings = try XCTUnwrap(storageManager.viewStorage.loadShippingLabelAccountSettings(siteID: sampleSiteID))
        XCTAssertEqual(storedSettings.siteID, sampleSiteID)
        XCTAssertEqual(storedSettings.toReadOnly(), accountSettings)
        XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: Storage.ShippingLabelPaymentMethod.self), 1)
    }

    // MARK: `loadPackages`

    func test_loadPackages_returns_success_response_with_rates() throws {
        // Given
        let remote = MockWooShippingRemote()
        let response = WooShippingPackagesResponse.fake().copy(customPackages: [WooShippingCustomPackage.fake()])
        remote.whenLoadPackages(siteID: sampleSiteID, thenReturn: .success(response))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingPackagesResponse, Error> = waitFor { promise in
            let action = WooShippingAction.loadPackages(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let actualResponse = try result.get()
        XCTAssertEqual(actualResponse, response)
    }

    func test_loadPackages_when_successful_then_upserts_packages_into_storage() throws {
        // Given
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "packages", filename: "wooshipping-get-packages-success")

        // Confidence check
        XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: StorageWooShippingPackagesResponse.self), 0)

        // When
        let onSuccess: Bool = waitFor { promise in
            let action = WooShippingAction.loadPackages(siteID: self.sampleSiteID) { result in
                promise(result.isSuccess)
            }
            store.onAction(action)
        }

        let storedPackages = try XCTUnwrap(storageManager.viewStorage.firstObject(ofType: StorageWooShippingPackagesResponse.self)).toReadOnly()

        // Then
        XCTAssertTrue(onSuccess)
        XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: StorageWooShippingPackagesResponse.self), 1)
        XCTAssertEqual(storedPackages.siteID, sampleSiteID)
        XCTAssertEqual(storedPackages.allPredefinedOptions.count, 2)
        XCTAssertEqual(storedPackages.allPredefinedOptions.first?.predefinedOptions.count, 1)
        XCTAssertEqual(storedPackages.allPredefinedOptions.first?.predefinedOptions.first?.predefinedPackages.count, 2)
        XCTAssertEqual(storedPackages.customPackages.count, 1)
        XCTAssertEqual(storedPackages.customPackages.first?.name, "Custom name")
        XCTAssertEqual(storedPackages.customPackages.first?.boxWeight, 0.01)
        XCTAssertEqual(storedPackages.customPackages.first?.id, "849225dc153")
        XCTAssertEqual(storedPackages.customPackages.first?.type, .box)
        XCTAssertEqual(storedPackages.customPackages.first?.dimensions, "12 x 12 x 12")
        XCTAssertEqual(storedPackages.savedPredefinedPackages.count, 2)
        XCTAssertTrue(storedPackages.savedPredefinedPackages.contains(where: { $0.package.id == "small_flat_box" }))
    }

    func test_loadPackages_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedError = NetworkError.notFound()
        remote.whenLoadPackages(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingPackagesResponse, Error> = waitFor { promise in
            let action = WooShippingAction.loadPackages(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // MARK: `purchaseShippingLabel`

    func test_purchaseShippingLabel_returns_shipping_label_on_success_and_persists_label_in_storage() throws {
        // Given
        let expectedLabel = ShippingLabel.fake().copy(siteID: sampleSiteID, orderID: sampleOrderID, shippingLabelID: 13579, shipmentID: "0")
        let labelStatusResponse = ShippingLabelStatusPollingResponse.purchased(expectedLabel)
        let remote = MockWooShippingRemote()
        remote.whenPurchaseShippingLabel(siteID: sampleSiteID, thenReturn: .success([ShippingLabelPurchase.fake().copy(shippingLabelID: 13579)]))
        remote.whenCheckLabelStatus(siteID: sampleSiteID, thenReturn: .success(labelStatusResponse))

        let order = insertOrder(siteID: sampleSiteID, orderID: sampleOrderID)
        let shipment = insertShipment(siteID: sampleSiteID, orderID: sampleOrderID, index: "0")
        shipment.order = order

        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<ShippingLabel, Error> = waitFor(timeout: 10) { promise in
            let action = WooShippingAction.purchaseShippingLabel(siteID: self.sampleSiteID,
                                                                 orderID: self.sampleOrderID,
                                                                 originAddress: .fake(),
                                                                 destinationAddress: .fake(),
                                                                 package: .fake(),
                                                                 markOrderComplete: false,
                                                                 backendProcessingDelay: 0.0,
                                                                 pollingDelay: 0.0) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let actualLabel = try XCTUnwrap(result.get())
        XCTAssertEqual(actualLabel, expectedLabel)

        // label is persisted
        let storedLabels = storageManager.viewStorage.loadAllShippingLabels(siteID: sampleSiteID, orderID: sampleOrderID)
        XCTAssertEqual(storedLabels.count, 1)
        XCTAssertEqual(storedLabels.first?.shippingLabelID, expectedLabel.shippingLabelID)

        let storedShipments = storageManager.viewStorage.loadAllShipments(siteID: sampleSiteID, orderID: sampleOrderID)
        XCTAssertEqual(storedShipments.count, 1)
        XCTAssertEqual(storedShipments.first?.shippingLabel?.shippingLabelID, expectedLabel.shippingLabelID)
    }

    func test_purchaseShippingLabel_returns_error_on_purchaseShippingLabel_request_failure() throws {
        // Given
        let expectedError = NetworkError.timeout()
        let remote = MockWooShippingRemote()
        remote.whenPurchaseShippingLabel(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<ShippingLabel, Error> = waitFor { promise in
            let action = WooShippingAction.purchaseShippingLabel(siteID: self.sampleSiteID,
                                                                 orderID: self.sampleOrderID,
                                                                 originAddress: .fake(),
                                                                 destinationAddress: .fake(),
                                                                 package: .fake(),
                                                                 markOrderComplete: false,
                                                                 backendProcessingDelay: 0.0,
                                                                 pollingDelay: 0.0) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // slow
    func test_purchaseShippingLabel_returns_error_on_checkLabelStatus_request_failure() throws {
        // Given
        let expectedError = NetworkError.timeout()
        let remote = MockWooShippingRemote()
        remote.whenPurchaseShippingLabel(siteID: sampleSiteID, thenReturn: .success([ShippingLabelPurchase.fake().copy(shippingLabelID: 13579)]))
        remote.whenCheckLabelStatus(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<ShippingLabel, Error> = waitFor { promise in
            let action = WooShippingAction.purchaseShippingLabel(siteID: self.sampleSiteID,
                                                                 orderID: self.sampleOrderID,
                                                                 originAddress: .fake(),
                                                                 destinationAddress: .fake(),
                                                                 package: .fake(),
                                                                 markOrderComplete: false,
                                                                 backendProcessingDelay: 0.01,
                                                                 pollingDelay: 0.01,
                                                                 pollingMaximumRetries: 3) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    func test_purchaseShippingLabel_returns_error_on_purchase_error() throws {
        // Given
        let expectedLabel = ShippingLabel.fake().copy(shippingLabelID: 13579, status: .purchaseError)
        let labelStatusResponse = ShippingLabelStatusPollingResponse.purchased(expectedLabel)
        let remote = MockWooShippingRemote()
        remote.whenPurchaseShippingLabel(siteID: sampleSiteID, thenReturn: .success([ShippingLabelPurchase.fake().copy(shippingLabelID: 13579)]))
        remote.whenCheckLabelStatus(siteID: sampleSiteID, thenReturn: .success(labelStatusResponse))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<ShippingLabel, Error> = waitFor { promise in
            let action = WooShippingAction.purchaseShippingLabel(siteID: self.sampleSiteID,
                                                                 orderID: self.sampleOrderID,
                                                                 originAddress: .fake(),
                                                                 destinationAddress: .fake(),
                                                                 package: .fake(),
                                                                 markOrderComplete: false,
                                                                 backendProcessingDelay: 0.0,
                                                                 pollingDelay: 0.0) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? WooShippingLabelPurchaseError, .purchaseErrorStatus)
    }

    func test_purchaseShippingLabel_does_not_return_error_if_purchase_remains_in_progress() throws {
        // Given
        let inProgressLabel = ShippingLabel.fake().copy(shippingLabelID: 13579, status: .purchaseInProgress)
        let labelStatusResponse = ShippingLabelStatusPollingResponse.purchased(inProgressLabel)
        let remote = MockWooShippingRemote()
        remote.whenPurchaseShippingLabel(siteID: sampleSiteID, thenReturn: .success([ShippingLabelPurchase.fake().copy(shippingLabelID: 13579)]))
        remote.whenCheckLabelStatus(siteID: sampleSiteID, thenReturn: .success(labelStatusResponse))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        var purchaseResult: Result<ShippingLabel, Error>? = nil
        let action = WooShippingAction.purchaseShippingLabel(siteID: self.sampleSiteID,
                                                             orderID: self.sampleOrderID,
                                                             originAddress: .fake(),
                                                             destinationAddress: .fake(),
                                                             package: .fake(),
                                                             markOrderComplete: false,
                                                             backendProcessingDelay: 0.01,
                                                             pollingDelay: 0.01,
                                                             // Irrelevant, because it caps retries on error only.
                                                             // Here just for reference.
                                                             pollingMaximumRetries: 3,
                                                             completion: { purchaseResult = $0 })

        // We want to test that purchaseShippingLabel does not call its completion ("return") with
        // an error for the entire duration of the polling it makes under the hood when the status
        // is progress. So, let's set an inverted expectation: Let's validate that the result will
        // never be an error.
        let exp = expectation(
            for: NSPredicate(block: { _, _ in
                switch purchaseResult {
                case .failure: return true
                default: return false
                }
            }),
            evaluatedWith: nil
        )
        exp.isInverted = true

        // When
        store.onAction(action)

        // Then
        //
        // The action has been dispatched and should result in:
        //
        // 1. API call to get the purchase labels
        // 2. Wait for the given delay to "give the backend time to process the labels"
        // 3. API call to get the status of those labels, which will be "in progress"
        // 4. Another API call after a delay to check the status again
        // 5. More API calls to check the status, because there currently is no limit to how many retries we fire...
        //
        // By waiting for an interval greater than the sum of the delays on the inverted expectation we will:
        //
        // - Simulate the whole process, including the retry mechanism
        // - Ensure that the completion never gets called with an error throughout the process
        //
        // The delays configured above are both 0.01. Using a 0.1 timeout – one order of magnitude bigger –
        wait(for: [exp], timeout: 0.1)

        // To ensure we didn't get a false positive, with the test simply waiting for the given timeout
        // but nothing happening in the SUT, let's inspect the remote test double to ensure that both
        // the purchase labels and the check status API calls were made. For the status, let's also
        // verify more that one was made, to ensure that it polled upon a "in progress" status.
        XCTAssertTrue(remote.purchaseShippingLabelCalled)
        XCTAssertGreaterThan(remote.checkLabelStatusCallsCount, 1)
    }

    func test_printLabel_returns_print_data_on_success() throws {
        // Given
        let expectedPrintData = ShippingLabelPrintData.fake()
        let remote = MockWooShippingRemote()
        remote.whenPrintLabel(siteID: sampleSiteID, thenReturn: .success(expectedPrintData))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let printData: ShippingLabelPrintData = waitFor { promise in
            let action = WooShippingAction.printLabel(siteID: self.sampleSiteID,
                                                      labelIDs: [123],
                                                      paperSize: .letter) { result in
                guard let printData = try? result.get() else {
                    XCTFail("Error printing shipping label: \(String(describing: result.failure))")
                    return
                }
                promise(printData)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(printData, expectedPrintData)
    }

    func test_printLabel_returns_error_on_failure() throws {
        // Given
        let expectedError = NetworkError.timeout()
        let remote = MockWooShippingRemote()
        remote.whenPrintLabel(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let error: Error = waitFor { promise in
            let action = WooShippingAction.printLabel(siteID: self.sampleSiteID,
                                                      labelIDs: [123],
                                                      paperSize: .letter) { result in
                guard let printData = result.failure else {
                    XCTFail("Unexpected result when printing shipping label: \(result)")
                    return
                }
                promise(printData)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    func test_loadOriginAddresses_returns_addresses_on_success() {
        // Given
        let expectedAddresses: [WooShippingOriginAddress] = [WooShippingOriginAddress.fake()]
        let remote = MockWooShippingRemote()
        remote.whenOriginAddresses(siteID: sampleSiteID, thenReturn: .success(expectedAddresses))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let addresses: [WooShippingOriginAddress] = waitFor { promise in
            let action = WooShippingAction.loadOriginAddresses(siteID: self.sampleSiteID) { result in
                guard let printData = try? result.get() else {
                    XCTFail("Error loading origin addresses for shipping label: \(String(describing: result.failure))")
                    return
                }
                promise(printData)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(addresses, expectedAddresses)
    }

    func test_loadOriginAddresses_returns_error_failure() {
        // Given
        let expectedError = NetworkError.timeout()
        let remote = MockWooShippingRemote()
        remote.whenOriginAddresses(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let error: Error = waitFor { promise in
            let action = WooShippingAction.loadOriginAddresses(siteID: self.sampleSiteID) { result in
                guard let printData = result.failure else {
                    XCTFail("Unexpected result when printing shipping label: \(result)")
                    return
                }
                promise(printData)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    func test_loadOriginAddresses_persists_fetched_addresses_to_local_storage_on_success() {
        // Given
        let address1 = WooShippingOriginAddress(
            siteID: sampleSiteID,
            id: "address1",
            company: "Company A",
            address1: "123 Main St",
            address2: "Suite 100",
            city: "San Francisco",
            state: "CA",
            postcode: "94102",
            country: "US",
            phone: "555-0123",
            firstName: "John",
            lastName: "Doe",
            email: "john@company.com",
            defaultAddress: true,
            isVerified: false
        )
        let address2 = WooShippingOriginAddress(
            siteID: sampleSiteID,
            id: "address2",
            company: "Company B",
            address1: "456 Oak Ave",
            address2: "",
            city: "Los Angeles",
            state: "CA",
            postcode: "90210",
            country: "US",
            phone: "555-0456",
            firstName: "Jane",
            lastName: "Smith",
            email: "jane@companyb.com",
            defaultAddress: false,
            isVerified: true
        )
        let expectedAddresses = [address1, address2]

        let remote = MockWooShippingRemote()
        remote.whenOriginAddresses(siteID: sampleSiteID, thenReturn: .success(expectedAddresses))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Confidence check - no addresses in storage initially
        XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: StorageWooShippingOriginAddress.self), 0)

        // When
        let onSuccess: Bool = waitFor { promise in
            let action = WooShippingAction.loadOriginAddresses(siteID: self.sampleSiteID) { result in
                promise(result.isSuccess)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(onSuccess)

        // Verify addresses are persisted to storage
        let storedAddresses = storageManager.viewStorage.loadAllOriginAddresses(siteID: sampleSiteID)
        XCTAssertEqual(storedAddresses.count, 2)

        // Verify first address details
        let storedAddress1 = storedAddresses.first { $0.id == "address1" }
        XCTAssertNotNil(storedAddress1)
        XCTAssertEqual(storedAddress1?.company, "Company A")
        XCTAssertEqual(storedAddress1?.address1, "123 Main St")
        XCTAssertEqual(storedAddress1?.address2, "Suite 100")
        XCTAssertEqual(storedAddress1?.city, "San Francisco")
        XCTAssertEqual(storedAddress1?.state, "CA")
        XCTAssertEqual(storedAddress1?.postcode, "94102")
        XCTAssertEqual(storedAddress1?.country, "US")
        XCTAssertEqual(storedAddress1?.phone, "555-0123")
        XCTAssertEqual(storedAddress1?.firstName, "John")
        XCTAssertEqual(storedAddress1?.lastName, "Doe")
        XCTAssertEqual(storedAddress1?.email, "john@company.com")
        XCTAssertEqual(storedAddress1?.defaultAddress, true)
        XCTAssertEqual(storedAddress1?.isVerified, false)

        // Verify second address details
        let storedAddress2 = storedAddresses.first { $0.id == "address2" }
        XCTAssertNotNil(storedAddress2)
        XCTAssertEqual(storedAddress2?.company, "Company B")
        XCTAssertEqual(storedAddress2?.address1, "456 Oak Ave")
        XCTAssertEqual(storedAddress2?.address2, "")
        XCTAssertEqual(storedAddress2?.city, "Los Angeles")
        XCTAssertEqual(storedAddress2?.state, "CA")
        XCTAssertEqual(storedAddress2?.postcode, "90210")
        XCTAssertEqual(storedAddress2?.country, "US")
        XCTAssertEqual(storedAddress2?.phone, "555-0456")
        XCTAssertEqual(storedAddress2?.firstName, "Jane")
        XCTAssertEqual(storedAddress2?.lastName, "Smith")
        XCTAssertEqual(storedAddress2?.email, "jane@companyb.com")
        XCTAssertEqual(storedAddress2?.defaultAddress, false)
        XCTAssertEqual(storedAddress2?.isVerified, true)

        // Verify read-only conversion works correctly
        let readOnlyAddresses = storedAddresses
            .map { $0.toReadOnly() }
            .sorted(by: { $0.id < $1.id })
        XCTAssertEqual(readOnlyAddresses, expectedAddresses)
    }

    // MARK: `validateAddress`

    func test_validateAddress_returns_WooShippingAddressValidationSuccess_on_success() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedResult = WooShippingAddressValidationSuccess(normalizedAddress: WooShippingNormalizedAddress.fake(),
                                                                 originalAddress: WooShippingAddress.fake(),
                                                                 isTrivialNormalization: true)
        remote.whenAddressValidation(siteID: sampleSiteID, thenReturn: .success(expectedResult))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingAddressValidationSuccess, Error> = waitFor { promise in
            let action = WooShippingAction.validateAddress(siteID: self.sampleSiteID,
                                                           address: WooShippingAddress.fake()) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let validationSuccess = try XCTUnwrap(result.get())
        XCTAssertEqual(validationSuccess, expectedResult)
    }

    func test_validateAddress_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedError = WooShippingAddressValidationError(addressError: "House number not found", generalError: nil, nameError: nil)
        remote.whenAddressValidation(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingAddressValidationSuccess, Error> = waitFor { promise in
            let action = WooShippingAction.validateAddress(siteID: self.sampleSiteID,
                                                           address: WooShippingAddress.fake()) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? WooShippingAddressValidationError, expectedError)
    }

    // MARK: `updateOriginAddress`

    func test_updateOriginAddress_returns_success_response() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedAddressUpdate = WooShippingOriginAddressUpdate(address: WooShippingOriginAddress.fake(), isVerified: true)
        remote.whenUpdatingOriginAddress(siteID: sampleSiteID, thenReturn: .success(expectedAddressUpdate))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingOriginAddressUpdate, Error> = waitFor { promise in
            let action = WooShippingAction.updateOriginAddress(siteID: self.sampleSiteID,
                                                               address: WooShippingOriginAddress.fake(),
                                                               isVerified: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let actualAddressUpdate = try XCTUnwrap(result.get())
        XCTAssertEqual(actualAddressUpdate, expectedAddressUpdate)
    }

    func test_updateOriginAddress_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedError = NetworkError.timeout()
        remote.whenUpdatingOriginAddress(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingOriginAddressUpdate, Error> = waitFor { promise in
            let action = WooShippingAction.updateOriginAddress(siteID: self.sampleSiteID,
                                                               address: WooShippingOriginAddress.fake(),
                                                               isVerified: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // MARK: `verifyDestinationAddress`

    func test_verifyDestinationAddress_returns_WooShippingVerifyDestinationAddressSuccess_on_success() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedResult = WooShippingVerifyDestinationAddressSuccess(normalizedAddress: WooShippingNormalizedAddress.fake(),
                                                                        isTrivialNormalization: true,
                                                                        isVerified: true)
        remote.whenVerifyDestinationAddress(siteID: sampleSiteID, thenReturn: .success(expectedResult))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingVerifyDestinationAddressSuccess, Error> = waitFor { promise in
            let action = WooShippingAction.verifyDestinationAddress(siteID: self.sampleSiteID,
                                                                    orderID: self.sampleOrderID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let validationSuccess = try XCTUnwrap(result.get())
        XCTAssertEqual(validationSuccess, expectedResult)
    }

    func test_verifyDestinationAddress_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedError = WooShippingAddressValidationError(addressError: "House number not found", generalError: nil, nameError: nil)
        remote.whenVerifyDestinationAddress(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingVerifyDestinationAddressSuccess, Error> = waitFor { promise in
            let action = WooShippingAction.verifyDestinationAddress(siteID: self.sampleSiteID,
                                                                    orderID: self.sampleOrderID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? WooShippingAddressValidationError, expectedError)
    }

    // MARK: `updateDestinationAddress`

    func test_updateDestinationAddress_returns_success_response() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedAddressUpdate = WooShippingDestinationAddressUpdate(address: WooShippingDestinationAddress.fake(), isVerified: true)
        remote.whenUpdatingDestinationAddress(siteID: sampleSiteID, thenReturn: .success(expectedAddressUpdate))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingDestinationAddressUpdate, Error> = waitFor { promise in
            let action = WooShippingAction.updateDestinationAddress(siteID: self.sampleSiteID,
                                                                    orderID: self.sampleOrderID,
                                                                    address: WooShippingDestinationAddress.fake(),
                                                                    isVerified: true) { result in
                promise(result)
            }
            store.onAction(action)
        }


        // Then
        let actualAddressUpdate = try XCTUnwrap(result.get())
        XCTAssertEqual(actualAddressUpdate, expectedAddressUpdate)
    }

    func test_updateDestinationAddress_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedError = NetworkError.timeout()
        remote.whenUpdatingDestinationAddress(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingDestinationAddressUpdate, Error> = waitFor { promise in
            let action = WooShippingAction.updateDestinationAddress(siteID: self.sampleSiteID,
                                                                    orderID: self.sampleOrderID,
                                                                    address: WooShippingDestinationAddress.fake(),
                                                                    isVerified: true) { result in
                promise(result)
            }
            store.onAction(action)
        }



        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // MARK: `loadConfig`

    func test_loadConfig_returns_success_response() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedConfig = WooShippingConfig.fake().copy(shipments: [WooShippingShipment.fake()])
        remote.whenLoadingConfig(siteID: sampleSiteID, thenReturn: .success(expectedConfig))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingConfig, Error> = waitFor { promise in
            let action = WooShippingAction.loadConfig(siteID: self.sampleSiteID,
                                                      orderID: self.sampleOrderID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let actualConfig = try XCTUnwrap(result.get())
        XCTAssertEqual(actualConfig, expectedConfig)
    }

    func test_loadConfig_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedError = NetworkError.timeout()
        remote.whenLoadingConfig(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingConfig, Error> = waitFor { promise in
            let action = WooShippingAction.loadConfig(siteID: self.sampleSiteID,
                                                      orderID: self.sampleOrderID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // MARK: `updateShipment`

    func test_updateShipment_returns_success_response_and_persists_shipments() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expected = ["0": [WooShippingShipmentItem.fake()]]
        remote.whenUpdatingShipment(siteID: sampleSiteID, thenReturn: .success(expected))

        insertOrder(siteID: sampleSiteID, orderID: sampleOrderID)
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingShipments, Error> = waitFor { promise in
            let action = WooShippingAction.updateShipment(siteID: self.sampleSiteID,
                                                          orderID: self.sampleOrderID,
                                                          shipmentToUpdate: WooShippingUpdateShipment.fake()) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let actual = try XCTUnwrap(result.get())
        XCTAssertEqual(actual, expected)

        let storedShipments = storageManager.viewStorage.loadAllShipments(siteID: sampleSiteID, orderID: sampleOrderID)
        XCTAssertEqual(storedShipments.count, 1)
        XCTAssertEqual(storedShipments.first?.index, "0")
    }

    func test_updateShipment_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedError = NetworkError.timeout()
        remote.whenUpdatingShipment(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingShipments, Error> = waitFor { promise in
            let action = WooShippingAction.updateShipment(siteID: self.sampleSiteID,
                                                          orderID: self.sampleOrderID,
                                                          shipmentToUpdate: WooShippingUpdateShipment.fake()) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // MARK: - `refundShippingLabel`

    func test_refundShippingLabel_returns_updated_label_and_updates_stored_label_refund_on_success() throws {
        // Given
        let sampleOrderID: Int64 = 134
        let remote = MockWooShippingRemote()
        let expectedRefund = Yosemite.ShippingLabelRefund(dateRequested: Date(), status: .pending)
        let shippingLabel = MockShippingLabel.emptyLabel().copy(siteID: sampleSiteID, orderID: sampleOrderID, shippingLabelID: 123, shipmentID: "0")

        remote.whenRefundingShippingLabel(siteID: shippingLabel.siteID,
                                          orderID: shippingLabel.orderID,
                                          shippingLabelID: shippingLabel.shippingLabelID,
                                          thenReturn: .success(expectedRefund))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        let shipment = insertShipment(siteID: sampleSiteID, orderID: sampleOrderID, index: "0")
        // Inserts a shipping label without a refund.
        let storedLabel = insertShippingLabel(shippingLabel)
        shipment.shippingLabel = storedLabel

        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabel.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabelRefund.self), 0)

        // When
        let result: Result<Yosemite.ShippingLabel, Error> = waitFor { promise in
            let action = WooShippingAction.refundShippingLabel(shippingLabel: shippingLabel) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let label = try XCTUnwrap(result.get())
        XCTAssertEqual(label.refund, expectedRefund)

        let persistedShippingLabel = try XCTUnwrap(viewStorage.loadShippingLabel(siteID: shippingLabel.siteID,
                                                                                 orderID: shippingLabel.orderID,
                                                                                 shippingLabelID: shippingLabel.shippingLabelID))
        XCTAssertEqual(persistedShippingLabel.refund?.toReadOnly(), expectedRefund)

        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabel.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabelRefund.self), 1)

        let storedShipments = viewStorage.loadAllShipments(siteID: sampleSiteID, orderID: sampleOrderID)
        XCTAssertEqual(storedShipments.first?.shippingLabel?.shippingLabelID, shippingLabel.shippingLabelID)
        XCTAssertNotNil(storedShipments.first?.shippingLabel?.refund)
    }

    func test_refundShippingLabel_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedError = NetworkError.notFound()
        let shippingLabel = MockShippingLabel.emptyLabel().copy(siteID: sampleSiteID, orderID: 134, shippingLabelID: 132)

        remote.whenRefundingShippingLabel(siteID: shippingLabel.siteID,
                                          orderID: shippingLabel.orderID,
                                          shippingLabelID: shippingLabel.shippingLabelID,
                                          thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<Yosemite.ShippingLabel, Error> = waitFor { promise in
            let action = WooShippingAction.refundShippingLabel(shippingLabel: shippingLabel) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // MARK: - `updateAccountSettings`

    func test_updateAccountSettings_returns_true_on_success() throws {
        // Given
        let sampleOrderID: Int64 = 134
        let remote = MockWooShippingRemote()

        remote.whenUpdateAccountSettings(siteID: sampleOrderID, thenReturn: .success(true))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = WooShippingAction.updateAccountSettings(siteID: sampleOrderID, settings: .fake()) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(result.get()))
    }

    func test_updateAccountSettings_returns_error_on_failure() throws {
        // Given
        let sampleOrderID: Int64 = 134
        let remote = MockWooShippingRemote()
        let expectedError = NetworkError.notFound()

        remote.whenUpdateAccountSettings(siteID: sampleOrderID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = WooShippingAction.updateAccountSettings(siteID: sampleOrderID, settings: .fake()) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // MARK: - `acceptUPSTermsOfService`

    func test_acceptUPSTermsOfService_returns_true_on_success() throws {
        // Given
        let remote = MockWooShippingRemote()
        let originAddress = WooShippingAddress.fake()

        remote.whenAcceptingUPSTOS(siteID: sampleSiteID, originAddress: originAddress, thenReturn: .success(true))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = WooShippingAction.acceptUPSTermsOfService(siteID: self.sampleSiteID, originAddress: originAddress) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(result.get()))
    }

    func test_acceptUPSTermsOfService_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let originAddress = WooShippingAddress.fake()
        let expectedError = NetworkError.notFound()

        remote.whenAcceptingUPSTOS(siteID: sampleSiteID, originAddress: originAddress, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = WooShippingAction.acceptUPSTermsOfService(siteID: self.sampleSiteID, originAddress: originAddress) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // MARK: `syncShipments`

    func test_syncShipments_returns_shipments_on_success() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedShipments = [WooShippingShipment.fake(), WooShippingShipment.fake()]
        let config = WooShippingConfig.fake().copy(shipments: expectedShipments)
        remote.whenLoadingConfig(siteID: sampleSiteID, thenReturn: .success(config))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<[WooShippingShipment], Error> = waitFor { promise in
            let action = WooShippingAction.syncShipments(siteID: self.sampleSiteID,
                                                         orderID: self.sampleOrderID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let actualShipments = try XCTUnwrap(result.get())
        XCTAssertEqual(actualShipments, expectedShipments)
    }

    func test_syncShipments_returns_error_on_failure() throws {
        // Given
        let remote = MockWooShippingRemote()
        let expectedError = NetworkError.timeout()
        remote.whenLoadingConfig(siteID: sampleSiteID, thenReturn: .failure(expectedError))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<[WooShippingShipment], Error> = waitFor { promise in
            let action = WooShippingAction.syncShipments(siteID: self.sampleSiteID,
                                                         orderID: self.sampleOrderID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    func test_syncShipments_persists_shipments_to_storage_on_success() throws {
        // Given
        let remote = MockWooShippingRemote()
        insertOrder(siteID: sampleSiteID, orderID: sampleOrderID)

        let shippingLabel = ShippingLabel.fake().copy(
            siteID: sampleSiteID,
            orderID: sampleOrderID,
            shippingLabelID: 123
        )
        let item = WooShippingShipmentItem(id: 11, subItems: [])
        let expectedShipments = [WooShippingShipment.fake().copy(
            siteID: sampleSiteID,
            orderID: sampleOrderID,
            index: "0",
            items: [item],
            shippingLabel: shippingLabel
        )]
        let config = WooShippingConfig.fake().copy(shipments: expectedShipments)
        remote.whenLoadingConfig(siteID: sampleSiteID, thenReturn: .success(config))

        let store = WooShippingStore(dispatcher: dispatcher,
                                     storageManager: storageManager,
                                     network: network,
                                     remote: remote)

        // When
        let result: Result<[WooShippingShipment], Error> = waitFor { promise in
            let action = WooShippingAction.syncShipments(siteID: self.sampleSiteID,
                                                         orderID: self.sampleOrderID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageWooShippingShipment.self), expectedShipments.count)
        let object = viewStorage.loadAllShipments(siteID: sampleSiteID, orderID: sampleOrderID).first
        XCTAssertEqual(object?.order?.orderID, sampleOrderID)
        XCTAssertEqual(object?.shippingLabel?.shippingLabelID, shippingLabel.shippingLabelID)
        XCTAssertEqual(object?.items?.count, 1)
        XCTAssertEqual(object?.items?.first?.id, item.id)
    }
}

private extension WooShippingStoreTests {
    func sampleLabelRates() -> [ShippingLabelCarriersAndRates] {
        return [ShippingLabelCarriersAndRates(packageID: "123",
                                              defaultRates: [sampleLabelRate()],
                                              signatureRequired: [],
                                              adultSignatureRequired: [],
                                              carbonNeutral: [],
                                              saturdayDelivery: [],
                                              additionalHandling: [])]
    }

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

    func sampleCarrierPredefinedOptions() -> WooShippingCarrierPredefinedOptions {
        WooShippingCarrierPredefinedOptions(carrierID: "usps",
                                            predefinedOptions: [.init(title: "pri_flat_boxes",
                                                                      providerID: "usps",
                                                                      predefinedPackages: [.init(id: "small_flat_box",
                                                                                                 name: "",
                                                                                                 isLetter: false,
                                                                                                 dimensions: "",
                                                                                                 boxWeight: "",
                                                                                                 groupId: "")]),
                                                                .init(title: "pri_flat_envelopes",
                                                                      providerID: "usps",
                                                                      predefinedPackages: [.init(id: "flat_envelope",
                                                                                                 name: "",
                                                                                                 isLetter: true,
                                                                                                 dimensions: "",
                                                                                                 boxWeight: "",
                                                                                                 groupId: "")]),
                                                                .init(title: "pri_flat_boxes",
                                                                      providerID: "usps",
                                                                      predefinedPackages: [.init(id: "medium_flat_box_top",
                                                                                                 name: "",
                                                                                                 isLetter: false,
                                                                                                 dimensions: "",
                                                                                                 boxWeight: "",
                                                                                                 groupId: "")])])
    }

    @discardableResult
    func insertShippingLabel(_ readOnlyShippingLabel: Yosemite.ShippingLabel) -> StorageShippingLabel {
        let shippingLabel = viewStorage.insertNewObject(ofType: StorageShippingLabel.self)
        shippingLabel.update(with: readOnlyShippingLabel)
        return shippingLabel
    }

    @discardableResult
    func insertOrder(siteID: Int64, orderID: Int64) -> StorageOrder {
        let order = viewStorage.insertNewObject(ofType: StorageOrder.self)
        order.siteID = siteID
        order.orderID = orderID
        order.statusKey = ""
        return order
    }

    @discardableResult
    func insertShipment(siteID: Int64, orderID: Int64, index: String) -> StorageWooShippingShipment {
        let shipment = viewStorage.insertNewObject(ofType: StorageWooShippingShipment.self)
        shipment.siteID = siteID
        shipment.orderID = orderID
        shipment.index = index
        return shipment
    }
}
