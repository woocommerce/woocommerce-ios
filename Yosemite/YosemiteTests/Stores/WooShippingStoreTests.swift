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

}
