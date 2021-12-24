import XCTest
@testable import Yosemite
@testable import WooCommerce

private struct TestConstants {
    static let mockReaderID = "CHB204909005931"
}

final class CardReaderSettingsSearchingViewModelTests: XCTestCase {

    func test_did_change_should_show_returns_true_if_no_connected_readers() {
        let mockKnownReaderProvider = MockKnownReaderProvider()

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: #function)
        let _ = CardReaderSettingsSearchingViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isTrue)
            expectation.fulfill()
        }, knownReaderProvider: mockKnownReaderProvider)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_did_change_should_show_returns_false_if_reader_connected() {
        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: TestConstants.mockReaderID)

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: #function)

        let _ = CardReaderSettingsSearchingViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isFalse)
            expectation.fulfill()
        }, knownReaderProvider: mockKnownReaderProvider)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
