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
                .fulfillOnCompletion(expectation: receivedReaders)
        } receiveValue: { readers in
            if readers.count > 0 {
                readerService.cancelDiscovery()
                    .fulfillOnCompletion(expectation: receivedReaders)
            }
        }.store(in: &cancellables)

        try! readerService.start(MockTokenProvider())
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
                .fulfillOnCompletion(expectation: discoveredReaders)
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
                readerService.cancelDiscovery().discard()
                XCTFail()
                return
            }

            // We blisfully ignore the actual values received (for now)
            readerService.cancelDiscovery()
                .fulfillOnCompletion(expectation: discoveredReaders)
        }.store(in: &cancellables)

        try! readerService.start(MockTokenProvider())
        wait(for: [discoveredReaders], timeout: Constants.expectationTimeout)
    }

    func test_connecting_to_reader_works() {
        let discoveredReaders = expectation(description: "Discovered readers")
        let connectedToReader = expectation(description: "Connected to a reader")
        let connectedreaderIsPublished = expectation(description: "ConnectedReader is published")

        let readerService = ServiceLocator.cardReaderService

        readerService.discoveredReaders.dropFirst(1).sink { completion in
            readerService.cancelDiscovery()
                .fulfillOnCompletion(expectation: discoveredReaders)
        } receiveValue: { readers in
            // There should be at least one non nil reader
            guard let firstReader = readers.first else {
                return
            }
            discoveredReaders.fulfill()
            readerService.cancelDiscovery().discard()
            readerService.connect(firstReader).sink { completion in
                readerService.cancelDiscovery().discard()
            } receiveValue: { _ in
                readerService.cancelDiscovery()
                    .fulfillOnCompletion(expectation: connectedToReader)
            }.store(in: &self.cancellables)

        }.store(in: &cancellables)

        // Test also that connectedReaders is updated
        readerService.connectedReaders.sink { connectedReader in
            if connectedReader.count > 0 {
                connectedreaderIsPublished.fulfill()
            }
        }.store(in: &self.cancellables)

        try! readerService.start(MockTokenProvider())
        wait(for: [discoveredReaders, connectedToReader, connectedreaderIsPublished], timeout: Constants.expectationTimeout)
    }
}


private final class MockTokenProvider: CardReaderConfigProvider {
    func fetchToken(completion: @escaping(String?, Error?) -> Void) {
        completion("a token", nil)
    }

    func fetchDefaultLocationID(completion: @escaping(String?, Error?) -> Void) {
        completion("a location ID", nil)
    }
}

private extension Publisher {
    func fulfillOnCompletion(expectation: XCTestExpectation) {
        subscribe(Subscribers.Sink(
                    receiveCompletion: { _ in
                        expectation.fulfill()
                    },
                    receiveValue: { _ in }
        ))
    }
    func discard() {
        subscribe(Subscribers.Sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in }
        ))
    }
}
