import XCTest
import Combine
@testable import WooCommerce
@testable import Hardware


/// Integration tests for the integration with the Stripe Terminal SDK.
/// We want to reach into the ServiceLocator in all tests
/// because these are integration test, and we do not want to mock anything,
/// at this point, other than the actual hardware
final class StripeCardReaderIntegrationTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    // MARK: - Integration tests
    func test_start_discovery_updates_discovered_readers() {
        let receivedReaders = expectation(description: "Discovered Readers publishes values after discovery process starts")

        let readerService = ServiceLocator.cardReaderService

        readerService.discoveredReaders.sink { completion in
            readerService.cancelDiscovery()
            receivedReaders.fulfill()
        } receiveValue: { readers in
            if readers.count > 0 {
                readerService.cancelDiscovery()
                receivedReaders.fulfill()
            }
        }.store(in: &cancellables)

        readerService.start(MockTokenProvider())
        wait(for: [receivedReaders], timeout: Constants.expectationTimeout)
    }

    /// The observed behaviour is that when discovery starts, the Stripe SDK will
    /// call into its delegate with an empty array of "discovered readers".
    /// Later on, it will call into its delegate again everytime it discovers a reader
    /// passing the full list of readers discovered
    func test_start_discovery_updates_discovered_readers_at_least_twice() {
        let discoveredReaders = expectation(description: "Discovered Readers publishes first, an empty array, and then the actual reader(s) discovered")

        let readerService = ServiceLocator.cardReaderService

        readerService.discoveredReaders.sink { completion in
            readerService.cancelDiscovery()
            discoveredReaders.fulfill()
        } receiveValue: { readers in
            // The Stripe Terminal SDK published an empty list of discovered readers first
            // and it will continue publishing as new readers are discovered.
            // So we ignore the first call to receiveValue, and perform the test on the first call to
            // receive value that is receiving a non-empty array.
            guard !readers.isEmpty else {
                return
            }
            // There should be at least one non nil reader
            guard let _ = readers.first else {
                readerService.cancelDiscovery()
                XCTFail()
                return
            }

            // We blisfully ignore the actual values received (for now)
            readerService.cancelDiscovery()
            discoveredReaders.fulfill()
        }.store(in: &cancellables)

        readerService.start(MockTokenProvider())
        wait(for: [discoveredReaders], timeout: Constants.expectationTimeout)
    }

    func test_connecting_to_reader_works() {
        let discoveredReaders = expectation(description: "Discovered readers")
        let connectedToReader = expectation(description: "Connected to a reader")
        let connectedreaderIsPublished = expectation(description: "ConnectedReader is published")

        let readerService = ServiceLocator.cardReaderService

        readerService.discoveredReaders.dropFirst(1).sink { completion in
            readerService.cancelDiscovery()
            discoveredReaders.fulfill()
        } receiveValue: { readers in
            // There should be at least one non nil reader
            guard let firstReader = readers.first else {
                return
            }
            discoveredReaders.fulfill()
            readerService.cancelDiscovery()
            readerService.connect(firstReader).sink { completion in
                readerService.cancelDiscovery()
            } receiveValue: { _ in
                readerService.cancelDiscovery()
                connectedToReader.fulfill()
            }.store(in: &self.cancellables)

        }.store(in: &cancellables)

        // Test also that connectedReaders is updated
        readerService.connectedReaders.sink { connectedReader in
            if connectedReader.count > 0 {
                connectedreaderIsPublished.fulfill()
            }
        }.store(in: &self.cancellables)

        readerService.start(MockTokenProvider())
        wait(for: [discoveredReaders, connectedToReader, connectedreaderIsPublished], timeout: Constants.expectationTimeout)
    }

    func test_creating_intent_fails_while_discovery_is_in_progress() {
        let intentCreation = expectation(description: "Creating a Payment Intent")

        let readerService = ServiceLocator.cardReaderService
        readerService.start(MockTokenProvider())

        let parameters = PaymentIntentParameters(amount: 100, currency: "usd", receiptDescription: "receipt", statementDescription: "statement")

        /// Payment intent creation completes with an error:
        /// Could not execute createPaymentIntent because the SDK is busy with another command: discoverReaders
        readerService.createPaymentIntent(parameters).sink { completion in
            intentCreation.fulfill()
        } receiveValue: { _ in
        }.store(in: &cancellables)


        wait(for: [intentCreation], timeout: Constants.expectationTimeout)
    }

    func test_creating_intent_succeedes_after_discovery_is_completed() {
        let discoveredReaders = expectation(description: "Discovered readers")
        let intentCreation = expectation(description: "Creating a Payment Intent")

        let readerService = ServiceLocator.cardReaderService

        let parameters = PaymentIntentParameters(amount: 100, currency: "usd", receiptDescription: "receipt", statementDescription: "statement")

        readerService.discoveredReaders.dropFirst(1).sink { completion in
            readerService.cancelDiscovery()
            discoveredReaders.fulfill()
        } receiveValue: { readers in
            // There should be at least one non nil reader
            readerService.cancelDiscovery()
            guard let _ = readers.first else {
                return
            }
            discoveredReaders.fulfill()
            readerService.createPaymentIntent(parameters).sink { completion in
                //
                print("== = completion")
            } receiveValue: { intent in
                XCTAssertFalse(intent.id.isEmpty)
                XCTAssertEqual(intent.amount, parameters.amount)
                XCTAssertEqual(intent.currency, parameters.currency)
                intentCreation.fulfill()
            }.store(in: &self.cancellables)

        }.store(in: &cancellables)

        readerService.start(MockTokenProvider())
        wait(for: [discoveredReaders, intentCreation], timeout: Constants.expectationTimeout)
    }
}


private final class MockTokenProvider: CardReaderConfigProvider {
    func fetchToken(completion: @escaping(String?, Error?) -> Void) {
        completion("a token", nil)
    }
}
