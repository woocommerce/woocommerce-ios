import XCTest
@testable import Yosemite
@testable import Networking

final class WooShippingStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

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
                                                         packageID: WooShippingCustomPackage.fake().id) { result in
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
        let error = DotcomError.requestFailed
        remote.whenDeletePackage(siteID: sampleSiteID, thenReturn: .failure(error))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingCreatePackageResponse, Error> = waitFor { promise in
            let action = WooShippingAction.deletePackage(siteID: self.sampleSiteID,
                                                         packageID: WooShippingCustomPackage.fake().id) { result in
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
                                                         packageID: WooShippingCustomPackage.fake().id) { result in
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
                                                          originAddress: ShippingLabelAddress.fake(),
                                                          destinationAddress: ShippingLabelAddress.fake(),
                                                          packages: [ShippingLabelPackageSelected.fake()]) { result in
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
                                                          originAddress: ShippingLabelAddress.fake(),
                                                          destinationAddress: ShippingLabelAddress.fake(),
                                                          packages: [ShippingLabelPackageSelected.fake()]) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // MARK: `loadPackages`

    func test_loadPackages_returns_success_response_with_rates() throws {
        // Given
        let remote = MockWooShippingRemote()
        let response = WooShippingPackagesResponse.fake().copy(customPackages: [WooShippingCustomPackage.fake()])
        remote.whenLoadPackages(siteID: sampleSiteID, thenReturn: .success(response))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingPackagesResponse, WooShippingLoadPackagesError> = waitFor { promise in
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
        remote.whenLoadPackages(siteID: sampleSiteID, thenReturn: .failure(WooShippingLoadPackagesError.loadingFailed(error: expectedError)))
        let store = WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<WooShippingPackagesResponse, WooShippingLoadPackagesError> = waitFor { promise in
            let action = WooShippingAction.loadPackages(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, WooShippingLoadPackagesError.loadingFailed(error: expectedError))
    }

    // MARK: `purchaseShippingLabel`

    func test_purchaseShippingLabel_returns_shipping_label_on_success() throws {
        // Given
        let expectedLabel = ShippingLabel.fake().copy(shippingLabelID: 13579)
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
}

private extension WooShippingStoreTests {
    func sampleLabelRates() -> [ShippingLabelCarriersAndRates] {
        return [ShippingLabelCarriersAndRates(packageID: "123",
                                             defaultRates: [sampleLabelRate()],
                                             signatureRequired: [],
                                             adultSignatureRequired: [])]
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
}
