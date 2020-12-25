import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage

/// ShippingLabelStore Unit Tests
final class ShippingLabelStoreTests: XCTestCase {
    /// Mock Dispatcher!
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    private var viewStorage: StorageType {
        storageManager.viewStorage
    }

    private let sampleSiteID: Int64 = 123
    private let sampleShippingLabelID: Int64 = 1234

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        storageManager = nil
        dispatcher = nil
        super.tearDown()
    }

    // MARK: - `loadShippingLabels`

    func test_loadShippingLabels_persists_shipping_labels_and_settings_on_success() throws {
        // Given
        let remote = MockShippingLabelRemote()
        let orderID: Int64 = 22
        let expectedShippingLabel: Yosemite.ShippingLabel = {
            let origin = ShippingLabelAddress(company: "fun testing",
                                              name: "Woo seller",
                                              phone: "6501234567",
                                              country: "US",
                                              state: "CA",
                                              address1: "9999 19TH AVE",
                                              address2: "",
                                              city: "SAN FRANCISCO",
                                              postcode: "94121-2303")
            let destination = ShippingLabelAddress(company: "",
                                                   name: "Woo buyer",
                                                   phone: "1650345689",
                                                   country: "TW",
                                                   state: "Taiwan",
                                                   address1: "No 70 RA St",
                                                   address2: "",
                                                   city: "Taipei",
                                                   postcode: "100")
            let refund = ShippingLabelRefund(dateRequested: Date(timeIntervalSince1970: 1603716266.809), status: .pending)
            return ShippingLabel(siteID: sampleSiteID,
                                 orderID: orderID,
                                 shippingLabelID: 1149,
                                 carrierID: "usps",
                                 dateCreated: Date(timeIntervalSince1970: 1603716274.809),
                                 packageName: "box",
                                 rate: 58.81,
                                 currency: "USD",
                                 trackingNumber: "CM199912222US",
                                 serviceName: "USPS - Priority Mail International",
                                 refundableAmount: 58.81,
                                 status: .purchased,
                                 refund: refund,
                                 originAddress: origin,
                                 destinationAddress: destination,
                                 productIDs: [3013],
                                 productNames: ["Password protected!"])
        }()
        let expectedSettings = Yosemite.ShippingLabelSettings(siteID: sampleSiteID, orderID: orderID, paperSize: .letter)
        let expectedResponse = OrderShippingLabelListResponse(shippingLabels: [expectedShippingLabel], settings: expectedSettings)
        remote.whenLoadingShippingLabels(siteID: sampleSiteID, orderID: orderID, thenReturn: .success(expectedResponse))
        let store = ShippingLabelStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        insertOrder(siteID: sampleSiteID, orderID: orderID)

        // When
        let result: Result<Void, Error> = try waitFor { promise in
            let action = ShippingLabelAction.synchronizeShippingLabels(siteID: self.sampleSiteID, orderID: orderID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)

        let persistedOrder = try XCTUnwrap(viewStorage.loadOrder(siteID: sampleSiteID, orderID: orderID))
        let persistedShippingLabels = try XCTUnwrap(viewStorage.loadAllShippingLabels(siteID: sampleSiteID, orderID: orderID))
        XCTAssertEqual(persistedOrder.shippingLabels, Set(persistedShippingLabels))
        XCTAssertEqual(persistedShippingLabels.map { $0.toReadOnly() }, [expectedShippingLabel])

        let persistedSettings = try XCTUnwrap(viewStorage.loadShippingLabelSettings(siteID: sampleSiteID, orderID: orderID))
        XCTAssertEqual(persistedOrder.shippingLabelSettings, persistedSettings)
        XCTAssertEqual(persistedSettings.toReadOnly(), expectedSettings)
    }

    func test_loadShippingLabels_does_not_persist_shipping_labels_and_settings_on_success_with_empty_shipping_labels() throws {
        // Given
        let remote = MockShippingLabelRemote()
        let orderID: Int64 = 22
        let expectedSettings = Yosemite.ShippingLabelSettings(siteID: sampleSiteID, orderID: orderID, paperSize: .letter)
        // The response has no shipping labels but settings, to simulate an order without shipping labels.
        let expectedResponse = OrderShippingLabelListResponse(shippingLabels: [], settings: expectedSettings)
        remote.whenLoadingShippingLabels(siteID: sampleSiteID, orderID: orderID, thenReturn: .success(expectedResponse))
        let store = ShippingLabelStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        insertOrder(siteID: sampleSiteID, orderID: orderID)

        // When
        let result: Result<Void, Error> = try waitFor { promise in
            let action = ShippingLabelAction.synchronizeShippingLabels(siteID: self.sampleSiteID, orderID: orderID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertNoThrow(try XCTUnwrap(result.get()))

        let persistedOrder = try XCTUnwrap(viewStorage.loadOrder(siteID: sampleSiteID, orderID: orderID))
        XCTAssertEqual(persistedOrder.shippingLabels ?? [], [])
        XCTAssertNil(persistedOrder.shippingLabelSettings)

        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabel.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabelAddress.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabelRefund.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabelSettings.self), 0)
    }

    func test_loadShippingLabels_returns_error_on_failure() throws {
        // Given
        let remote = MockShippingLabelRemote()
        let orderID: Int64 = 22
        let expectedError = NetworkError.notFound
        remote.whenLoadingShippingLabels(siteID: sampleSiteID, orderID: orderID, thenReturn: .failure(expectedError))
        let store = ShippingLabelStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<Void, Error> = try waitFor { promise in
            let action = ShippingLabelAction.synchronizeShippingLabels(siteID: self.sampleSiteID, orderID: orderID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // MARK: - `printShippingLabel`

    func test_printShippingLabel_returns_ShippingLabelPrintData_on_success() throws {
        // Given
        let remote = MockShippingLabelRemote()
        let expectedPrintData = ShippingLabelPrintData(mimeType: "application/pdf", base64Content: "////")
        remote.whenPrintingShippingLabel(siteID: sampleSiteID,
                                         shippingLabelID: sampleShippingLabelID,
                                         paperSize: "label",
                                         thenReturn: .success(expectedPrintData))
        let store = ShippingLabelStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<ShippingLabelPrintData, Error> = try waitFor { promise in
            let action = ShippingLabelAction.printShippingLabel(siteID: self.sampleSiteID,
                                                                shippingLabelID: self.sampleShippingLabelID,
                                                                paperSize: .label) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let printData = try XCTUnwrap(result.get())
        XCTAssertEqual(printData, expectedPrintData)
    }

    func test_printShippingLabel_returns_ShippingLabelPrintData_on_failure() throws {
        // Given
        let remote = MockShippingLabelRemote()
        let expectedError = NetworkError.notFound
        remote.whenPrintingShippingLabel(siteID: sampleSiteID,
                                         shippingLabelID: sampleShippingLabelID,
                                         paperSize: "label",
                                         thenReturn: .failure(expectedError))
        let store = ShippingLabelStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<ShippingLabelPrintData, Error> = try waitFor { promise in
            let action = ShippingLabelAction.printShippingLabel(siteID: self.sampleSiteID,
                                                                shippingLabelID: self.sampleShippingLabelID,
                                                                paperSize: .label) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // MARK: - `refundShippingLabel`

    func test_refundShippingLabel_returns_refund_and_updates_local_ShippingLabel_refund_on_success() throws {
        // Given
        let remote = MockShippingLabelRemote()
        let expectedRefund = Yosemite.ShippingLabelRefund(dateRequested: Date(), status: .pending)
        let shippingLabel = MockShippingLabel.emptyLabel().copy(siteID: sampleSiteID, orderID: 134, shippingLabelID: sampleShippingLabelID)
        remote.whenRefundingShippingLabel(siteID: shippingLabel.siteID,
                                          orderID: shippingLabel.orderID,
                                          shippingLabelID: shippingLabel.shippingLabelID,
                                          thenReturn: .success(expectedRefund))
        let store = ShippingLabelStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // Inserts a shipping label without a refund.
        insertShippingLabel(shippingLabel)

        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabel.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabelRefund.self), 0)

        // When
        let result: Result<Yosemite.ShippingLabelRefund, Error> = try waitFor { promise in
            let action = ShippingLabelAction.refundShippingLabel(shippingLabel: shippingLabel) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let refund = try XCTUnwrap(result.get())
        XCTAssertEqual(refund, expectedRefund)

        let persistedShippingLabel = try XCTUnwrap(viewStorage.loadShippingLabel(siteID: shippingLabel.siteID,
                                                                                 orderID: shippingLabel.orderID,
                                                                                 shippingLabelID: shippingLabel.shippingLabelID))
        XCTAssertEqual(persistedShippingLabel.refund?.toReadOnly(), expectedRefund)

        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabel.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabelRefund.self), 1)
    }

    func test_refundShippingLabel_returns_refund_on_success_without_storage_changes_if_no_existing_ShippingLabel_in_storage() throws {
        // Given
        let remote = MockShippingLabelRemote()
        let expectedRefund = Yosemite.ShippingLabelRefund(dateRequested: Date(), status: .pending)
        let shippingLabel = MockShippingLabel.emptyLabel().copy(siteID: sampleSiteID, orderID: 134, shippingLabelID: sampleShippingLabelID)
        remote.whenRefundingShippingLabel(siteID: shippingLabel.siteID,
                                          orderID: shippingLabel.orderID,
                                          shippingLabelID: shippingLabel.shippingLabelID,
                                          thenReturn: .success(expectedRefund))
        let store = ShippingLabelStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabel.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabelRefund.self), 0)

        // When
        let result: Result<Yosemite.ShippingLabelRefund, Error> = try waitFor { promise in
            let action = ShippingLabelAction.refundShippingLabel(shippingLabel: shippingLabel) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let refund = try XCTUnwrap(result.get())
        XCTAssertEqual(refund, expectedRefund)

        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabel.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageShippingLabelRefund.self), 0)
    }

    func test_refundShippingLabel_returns_error_on_failure() throws {
        // Given
        let remote = MockShippingLabelRemote()
        let expectedError = NetworkError.notFound
        let shippingLabel = MockShippingLabel.emptyLabel().copy(siteID: sampleSiteID, orderID: 134, shippingLabelID: sampleShippingLabelID)
        remote.whenRefundingShippingLabel(siteID: shippingLabel.siteID,
                                          orderID: shippingLabel.orderID,
                                          shippingLabelID: shippingLabel.shippingLabelID,
                                          thenReturn: .failure(expectedError))
        let store = ShippingLabelStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<Yosemite.ShippingLabelRefund, Error> = try waitFor { promise in
            let action = ShippingLabelAction.refundShippingLabel(shippingLabel: shippingLabel) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
    }

    // MARK: `loadShippingLabelSettings`

    func test_loadShippingLabelSettings_returns_settings_if_it_exists_in_storage() throws {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(siteID: sampleSiteID, orderID: 208)
        let shippingLabelSettings = Yosemite.ShippingLabelSettings(siteID: shippingLabel.siteID, orderID: shippingLabel.orderID, paperSize: .letter)
        let store = ShippingLabelStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        insertShippingLabelSettings(shippingLabelSettings)

        // When
        let result: Yosemite.ShippingLabelSettings? = try waitFor { promise in
            let action = ShippingLabelAction.loadShippingLabelSettings(shippingLabel: shippingLabel) { settings in
                promise(settings)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(result, shippingLabelSettings)
    }

    func test_loadShippingLabelSettings_returns_nil_if_it_does_not_exist_in_storage() throws {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(siteID: sampleSiteID, orderID: 208)
        let store = ShippingLabelStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Yosemite.ShippingLabelSettings? = try waitFor { promise in
            let action = ShippingLabelAction.loadShippingLabelSettings(shippingLabel: shippingLabel) { settings in
                promise(settings)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(result, nil)
    }
}

private extension ShippingLabelStoreTests {
    func insertOrder(siteID: Int64, orderID: Int64) {
        let order = viewStorage.insertNewObject(ofType: StorageOrder.self)
        order.siteID = siteID
        order.orderID = orderID
        order.statusKey = ""
    }

    func insertShippingLabel(_ readOnlyShippingLabel: Yosemite.ShippingLabel) {
        let shippingLabel = viewStorage.insertNewObject(ofType: StorageShippingLabel.self)
        shippingLabel.update(with: readOnlyShippingLabel)
    }

    func insertShippingLabelSettings(_ readOnlyShippingLabelSettings: Yosemite.ShippingLabelSettings) {
        let shippingLabelSettings = viewStorage.insertNewObject(ofType: StorageShippingLabelSettings.self)
        shippingLabelSettings.update(with: readOnlyShippingLabelSettings)
    }
}
