import XCTest
import Combine
@testable import Hardware

/// This test suite should belong in `Hardware`, but the Stripe Terminal SDK
/// will crash, when running in test mode, if there is no Info.plist avaiable
/// with a certain set of keys.
final class StripeCardReaderTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    // MARK: - Integration tests
    func test_start_triggers_an_update_to_discovered_readers() {
        let receivedReaders = expectation(description: "Discovered Readers publishes values after discovery process starts")

        let readerService = StripeCardReaderService(tokenProvider: WCPayTokenProvider())

        readerService.discoveredReaders.sink { completion in
            receivedReaders.fulfill()
        } receiveValue: { readers in
            receivedReaders.fulfill()
        }.store(in: &cancellables)

        readerService.start()
        waitForExpectations(timeout: 5, handler: nil)
    }
}
