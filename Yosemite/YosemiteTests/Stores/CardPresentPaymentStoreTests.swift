import XCTest
import Fakes
@testable import Yosemite
@testable import Networking
@testable import Storage
@testable import Hardware

/// CardPresentPaymentStore Unit Tests
///
/// All mock properties are necessary because
/// CardPresentPaymentStore extends Store.
final class CardPresentPaymentStoreTests: XCTestCase {
    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Mock Card Reader Service: In memory
    private var mockCardReaderService: MockCardReaderService!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        mockCardReaderService = MockCardReaderService()
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil
        mockCardReaderService = nil

        super.tearDown()
    }

    // MARK: - CardPresentPaymentAction.startCardReaderDiscovery

    /// Verifies that CardPresentPaymentAction.startCardReaderDiscovery hits the `start` method in the service.
    ///
    func test_start_discovery_action_hits_start_in_service() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService)

        let action = CardPresentPaymentAction.startCardReaderDiscovery(siteID: sampleSiteID, onReaderDiscovered: { _ in }, onError: { _ in })

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockCardReaderService.didHitStart)
    }

    func test_start_discovery_action_returns_data_eventually() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService)

        let expectation = self.expectation(description: "Readers discovered")

        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: sampleSiteID,
            onReaderDiscovered: { _ in
                expectation.fulfill()
            },
            onError: { _ in }
        )

        cardPresentStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_start_discovery_action_passes_configuraton_provider_to_service() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService)

        let action = CardPresentPaymentAction.startCardReaderDiscovery(siteID: sampleSiteID, onReaderDiscovered: { _ in }, onError: { _ in })

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockCardReaderService.didReceiveAConfigurationProvider)
    }

    /// This test is meant to cover the error when there is a failure to fetch
    /// the connection token
    /// We do not have proper error handling for now, but it is in the pipeline
    /// https://github.com/woocommerce/woocommerce-ios/issues/3734
    /// https://github.com/woocommerce/woocommerce-ios/issues/3741
    /// This test will be edited to assert an error was received when
    /// proper error support is implemented. 
    func test_start_discovery_action_returns_empty_error_when_token_fetching_fails() {
        let expectation = self.expectation(description: "Empty readers on failure to obtain a connection token")

        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService)

        network.simulateResponse(requestUrlSuffix: "payments/connection_tokens", filename: "generic_error")

        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: sampleSiteID,
            onReaderDiscovered: { discoveredReaders in
                XCTAssertTrue(self.mockCardReaderService.didReceiveAConfigurationProvider)
                if discoveredReaders.count == 0 {
                    expectation.fulfill()
                }
            },
            onError: { _ in }
        )

        cardPresentStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_cancel_discovery_action_hits_cancel_in_service() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService)

        let action = CardPresentPaymentAction.cancelCardReaderDiscovery { result in
            //
        }

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockCardReaderService.didHitCancel)
    }

    /// We are still not handling errors, so we will need a new test here
    /// for the case when cancelation fails, which apparently is a thing
    func test_cancel_discovery_action_publishes_idle_as_new_discovery_status() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService)

        let expectation = self.expectation(description: "Cancelling discovery published idle as discoveryStatus")

        let action = CardPresentPaymentAction.cancelCardReaderDiscovery { result in
            if result.isSuccess {
                expectation.fulfill()
            }
        }

        cardPresentStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_cancel_discovery_after_start_rdpchanges_discovery_status_to_idle_eventually() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService)

        let expectation = self.expectation(description: "Cancelling discovery changes discoveryStatus to idle")

        let startDiscoveryAction = CardPresentPaymentAction.startCardReaderDiscovery(siteID: sampleSiteID, onReaderDiscovered: { _ in }, onError: { _ in })

        cardPresentStore.onAction(startDiscoveryAction)

        let action = CardPresentPaymentAction.cancelCardReaderDiscovery { result in
            print("=== hitting cancellation completion")
            if result.isSuccess {
                expectation.fulfill()
            }
        }

        cardPresentStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_connect_to_reader_action_updates_returns_provided_reader_on_success() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService)

        let expectation = self.expectation(description: "Connect to card reader")

        let reader = MockCardReader.bbposChipper2XBT()
        let action = CardPresentPaymentAction.connect(reader: reader) { result in
            switch result {
            case .failure:
                XCTFail()
            case .success(let connectedReader):
                XCTAssertEqual(connectedReader, reader)

                expectation.fulfill()
            }
        }

        cardPresentStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_disconnect_action_hits_disconnect_in_service() {
        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockCardReaderService)

        let action = CardPresentPaymentAction.disconnect(onCompletion: { result in
            //
        })

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockCardReaderService.didHitDisconnect)
    }
}
