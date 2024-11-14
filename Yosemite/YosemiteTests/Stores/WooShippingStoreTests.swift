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
        let error = DotcomError.unknown(code: "duplicate_custom_package_names_of_existing_packages",
                                        message: "At least one of the new custom packages has the same name as existing packages.")
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
        XCTAssertEqual(result.failure, .duplicatePackageNames)
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
}
