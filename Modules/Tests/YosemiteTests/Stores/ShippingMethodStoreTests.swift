import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage

/// ShippingMethodStore Unit Tests
final class ShippingMethodStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: - ShippingMethodStore.synchronizeShippingMethods

    /// Verifies that `ShippingMethodStore.synchronizeShippingMethods` effectively persists any retrieved `ShippingMethod`.
    ///
    func test_synchronizeShippingMethods_effectively_persists_retrieved_shipping_methods() {
        // Given
        let store = ShippingMethodStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "shipping_methods", filename: "shipping-methods")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ShippingMethod.self), 0)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = ShippingMethodAction.synchronizeShippingMethods(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ShippingMethod.self), 6)
        let flatRatePredicate = NSPredicate(format: "methodID == 'flat_rate'")
        let readOnlyShippingMethod = viewStorage.firstObject(ofType: Storage.ShippingMethod.self, matching: flatRatePredicate)?.toReadOnly()
        assertEqual(sampleShippingMethod(), readOnlyShippingMethod)
    }

    /// Verifies that `ShippingMethodStore.synchronizeShippingMethods` removes any `ShippingMethod` not included in the response.
    ///
    func test_synchronizeShippingMethods_removes_stale_shipping_methods_from_storage() {
        // Given
        let store = ShippingMethodStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "shipping_methods", filename: "shipping-methods")
        let staleShippingMethod = ShippingMethod(siteID: sampleSiteID, methodID: "stale", title: "Stale")
        insertShippingMethodToStorage(staleShippingMethod)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ShippingMethod.self), 1)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = ShippingMethodAction.synchronizeShippingMethods(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.ShippingMethod.self), 6)
        let staleMethodPredicate = NSPredicate(format: "methodID == 'stale'")
        XCTAssertNil(viewStorage.firstObject(ofType: Storage.ShippingMethod.self, matching: staleMethodPredicate))
    }

    /// Verifies that `ShippingMethodStore.synchronizeShippingMethods` returns an error whenever there is an error response from the backend.
    ///
    func test_synchronizeShippingMethods_returns_error_upon_response_error() {
        // Given
        let store = ShippingMethodStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "shipping_methods", filename: "generic_error")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = ShippingMethodAction.synchronizeShippingMethods(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `ShippingMethodStore.synchronizeShippingMethods` returns an error whenever there is no backend response.
    ///
    func test_synchronizeShippingMethods_returns_error_upon_empty_response() {
        // Given
        let store = ShippingMethodStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = ShippingMethodAction.synchronizeShippingMethods(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}

// MARK: - Private Methods
//
private extension ShippingMethodStoreTests {
    func sampleShippingMethod() -> Networking.ShippingMethod {
        return ShippingMethod(siteID: sampleSiteID, methodID: "flat_rate", title: "Flat rate")
    }

    func insertShippingMethodToStorage(_ readOnlyShippingMethod: Networking.ShippingMethod) {
        let storageShippingMethod = viewStorage.insertNewObject(ofType: Storage.ShippingMethod.self)
        storageShippingMethod.update(with: readOnlyShippingMethod)
    }
}
