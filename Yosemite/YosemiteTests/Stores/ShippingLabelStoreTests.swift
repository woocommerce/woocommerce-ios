import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage

/// ShippingLabelStore Unit Tests
final class ShippingLabelStoreTests: XCTestCase {
    /// Mockup Dispatcher!
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    private var network: MockupNetwork!

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
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    override func tearDown() {
        network = nil
        storageManager = nil
        dispatcher = nil
        super.tearDown()
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
}
