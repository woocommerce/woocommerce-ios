import XCTest
@testable import Yosemite
@testable import WooCommerce

private struct TestConstants {
    static let mockReaderID = "CHB204909005931"
}

final class CardReaderSettingsUnknownViewModelTests: XCTestCase {

    func test_did_change_should_show_returns_true_if_no_known_no_connected_readers() {
        let mockKnownReadersProvider = MockKnownReadersProvider()

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: "Check shouldShow returns isTrue")
        let _ = CardReaderSettingsUnknownViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isTrue)
            expectation.fulfill()
        }, knownReadersProvider: mockKnownReadersProvider)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_did_change_should_show_returns_false_if_reader_known() {
        let mockKnownReadersProvider = MockKnownReadersProvider(knownReaders: [TestConstants.mockReaderID])

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: "Check shouldShow returns isFalse")

        let _ = CardReaderSettingsUnknownViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isFalse)
            expectation.fulfill()
        }, knownReadersProvider: mockKnownReadersProvider)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_did_change_should_show_returns_false_if_reader_connected() {
        let mockKnownReadersProvider = MockKnownReadersProvider(knownReaders: [TestConstants.mockReaderID])

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: "Check shouldShow returns isFalse")

        let _ = CardReaderSettingsUnknownViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isFalse)
            expectation.fulfill()
        }, knownReadersProvider: mockKnownReadersProvider)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_did_change_should_show_returns_false_if_reader_known_and_connected() {
        let mockKnownReadersProvider = MockKnownReadersProvider(knownReaders: [TestConstants.mockReaderID])

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: "Check shouldShow returns isFalse")

        let _ = CardReaderSettingsUnknownViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isFalse)
            expectation.fulfill()
        }, knownReadersProvider: mockKnownReadersProvider)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
