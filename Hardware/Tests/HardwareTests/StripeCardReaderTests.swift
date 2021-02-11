import XCTest
import Combine
@testable import Hardware
//@testable import StripeTerminal

final class StripeCardReaderTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    func test_start_triggers_reader_discovery() {
        let receivedReaders = expectation(description: "readers received")

        let readerService = StripeCardReaderService(tokenProvider: WCPayTokenProvider())

        readerService.discoveredReaders.sink { completion in
            //
        } receiveValue: { readers in
            guard !readers.isEmpty else {
                XCTFail()
                return
            }

            receivedReaders.fulfill()
        }.store(in: &cancellables)

        readerService.start()
        waitForExpectations(timeout: 5, handler: nil)
    }

    static var allTests = [
        ("testReaderDiscoveryHitsSDK", test_start_triggers_reader_discovery),
    ]
}
