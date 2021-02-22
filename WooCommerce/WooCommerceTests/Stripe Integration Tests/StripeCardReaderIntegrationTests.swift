import XCTest
import Combine
@testable import WooCommerce
@testable import Hardware


/// Integration tests for the integration with the Stripe Terminal SDK.
/// We want to reach into the ServiceLocator in all tests
/// because these are integration test, and we do not want to mock anything,
/// at this point, other than the actual hardware
final class StripeCardReaderIntegrationTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    // MARK: - Integration tests
    func test_start_discovery_updates_discovered_readers() {
        let receivedReaders = expectation(description: "Discovered Readers publishes values after discovery process starts")

        let readerService = ServiceLocator.cardReaderService

        readerService.discoveredReaders.sink { completion in
            receivedReaders.fulfill()
        } receiveValue: { readers in
            receivedReaders.fulfill()
        }.store(in: &cancellables)

        readerService.start()
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_start_discovery_updates_discovered_readers__at_least_twice() {
        let receivedReaders = expectation(description: "Discovered Readers publishes first, an empty array, and then the actual reader(s) discovered")

        let readerService = ServiceLocator.cardReaderService

        readerService.discoveredReaders.sink { completion in
            receivedReaders.fulfill()
        } receiveValue: { readers in
            // The Stripe Terminal SDK published an empty list of discovered readers first
            // and it will continue publishing as new readers are discovered.
            // So we ignore the first call to receiveValue, and perform the test on the first call to
            // receive value that is receiving a non-empty array.
            guard !readers.isEmpty else {
                return
            }

            // There should be at least one non nil reader
            XCTAssertNotNil(readers.first)

            // We blisfully ignore the actual values received (for now)
            receivedReaders.fulfill()
        }.store(in: &cancellables)

        readerService.start()
        waitForExpectations(timeout: 10, handler: nil)
    }

}
