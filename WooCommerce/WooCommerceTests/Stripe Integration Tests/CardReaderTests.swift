import XCTest
import Combine
@testable import Hardware

/// This test suite should belong in `Hardware`, but the Stripe Terminal SDK
/// will crash, when running in test mode, if there is no Info.plist avaiable
/// with a certain set of keys.
final class CardReaderTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    /// The only way to test that CardReader is iniitalized correctly with a StripeTerminal.Reader is indirectly, via an integration test.
    func test_card_reader_can_be_initialized_by_card_reader_service() {
        let receivedReaders = expectation(description: "Discovered Readers publishes values after discovery process starts")

        let readerService = StripeCardReaderService(tokenProvider: WCPayTokenProvider())

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

            receivedReaders.fulfill()
        }.store(in: &cancellables)

        readerService.start()
        waitForExpectations(timeout: 10, handler: nil)
    }

    func test_card_reader_properties_are_initialized_according_to_expectations() {
        let receivedReaders = expectation(description: "Discovered Readers are initialized with the expected values")

        let readerService = StripeCardReaderService(tokenProvider: WCPayTokenProvider())

        let bbPOSReader = MockStripeCardReader.bbpos()

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

            guard let firstReader = readers.first else {
                XCTFail()
                return
            }

            // Now we assert that the properties in Hardware.Reader match
            // their counterparts in StripeTerminal.Reader
            XCTAssertEqual(firstReader.name, bbPOSReader.label)

            receivedReaders.fulfill()
        }.store(in: &cancellables)

        readerService.start()
        waitForExpectations(timeout: 10, handler: nil)
    }
}
