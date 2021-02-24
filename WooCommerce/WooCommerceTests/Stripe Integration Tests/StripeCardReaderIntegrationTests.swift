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

    /// The observed behaviour is that when discovery starts, the Stripe SDK will
    /// call into its delegate with an empty array of "discovered readers".
    /// Later on, it will call into its delegate again everytime it discovers a reader
    /// passing the full list of readers discovered
    func test_start_discovery_updates_discovered_readers_at_least_twice() {
        let discoveredReaders = expectation(description: "Discovered Readers publishes first, an empty array, and then the actual reader(s) discovered")

        let readerService = ServiceLocator.cardReaderService

        readerService.discoveredReaders.sink { completion in
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
                XCTFail()
                return
            }

            // We blisfully ignore the actual values received (for now)
            discoveredReaders.fulfill()
        }.store(in: &cancellables)

        readerService.start()
        waitForExpectations(timeout: 10, handler: nil)
    }

}
