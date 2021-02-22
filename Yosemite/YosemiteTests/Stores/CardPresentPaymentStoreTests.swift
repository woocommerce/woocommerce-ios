import XCTest
import Combine
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


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: - CardPresentPaymentAction.startCardReaderDiscovery

    /// Verifies that CardPresentPaymentAction.startCardReaderDiscovery hits the `start` method in the service.
    ///
    func test_start_discovery_action_hits_start_in_service() {
        let mockService = MockService()

        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockService)

        //let expectation = self.expectation(description: "Start discovery")

        let action = CardPresentPaymentAction.startCardReaderDiscovery { discoveredReaders in
            //
        }

        cardPresentStore.onAction(action)

        XCTAssertTrue(mockService.didHitStart)
    }

    func test_start_discovery_action_returns_data_eventually() {
        let mockService = MockService()

        let cardPresentStore = CardPresentPaymentStore(dispatcher: dispatcher,
                                                       storageManager: storageManager,
                                                       network: network,
                                                       cardReaderService: mockService)

        let expectation = self.expectation(description: "Readers discovered")

        let action = CardPresentPaymentAction.startCardReaderDiscovery { discoveredReaders in
            expectation.fulfill()
        }

        cardPresentStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


private final class MockService: CardReaderService {
    var discoveredReaders: AnyPublisher<[Hardware.CardReader], Never> {
        CurrentValueSubject<[Hardware.CardReader], Never>([]).eraseToAnyPublisher()
    }

    var connectedReaders: AnyPublisher<[Hardware.CardReader], Never> {
        CurrentValueSubject<[Hardware.CardReader], Never>([]).eraseToAnyPublisher()
    }

    var serviceStatus: AnyPublisher<CardReaderServiceStatus, Never> {
        CurrentValueSubject<CardReaderServiceStatus, Never>(.ready).eraseToAnyPublisher()
    }

    var discoveryStatus: AnyPublisher<CardReaderServiceDiscoveryStatus, Never> {
        CurrentValueSubject<CardReaderServiceDiscoveryStatus, Never>(.idle).eraseToAnyPublisher()
    }

    var paymentStatus: AnyPublisher<PaymentStatus, Never> {
        CurrentValueSubject<PaymentStatus, Never>(.notReady).eraseToAnyPublisher()
    }

    var readerEvents: AnyPublisher<CardReaderEvent, Never> {
        PassthroughSubject<CardReaderEvent, Never>().eraseToAnyPublisher()
    }

    var didHitStart = false

    init() {

    }

    func start() {
        didHitStart = true
    }

    func connect(_ reader: Hardware.CardReader) -> Future<Void, Error> {
        Future() { promise in
            // To be implemented
        }
    }

    func disconnect(_ reader: Hardware.CardReader) -> Future<Void, Error> {
        Future() { promise in
            // This will be removed. We just want to pretend we are doing a roundtrip to the SDK for now.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(Result.success(()))
            }
        }
    }

    func clear() { }

    func createPaymentIntent(_ parameters: PaymentIntentParameters) -> Future<PaymentIntent, Error> {
        Future() { promise in
            // To be implemented
        }
    }

    func collectPaymentMethod(_ intent: PaymentIntent) -> Future<PaymentIntent, Error> {
        Future() { promise in
            // To be implemented
        }
    }

    func processPaymentIntent(_ intent: PaymentIntent) -> Future<PaymentIntent, Error> {
        Future() { promise in
            // To be implemented
        }
    }

    func cancelPaymentIntent(_ intent: PaymentIntent) -> Future<PaymentIntent, Error> {
        Future() { promise in
            // To be implemented
        }
    }
}
