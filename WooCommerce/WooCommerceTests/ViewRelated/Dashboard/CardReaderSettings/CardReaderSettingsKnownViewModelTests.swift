import XCTest
@testable import Yosemite
@testable import WooCommerce

private struct TestConstants {
    static let mockReaderID = "CHB204909005931"
}

final class CardReaderSettingsKnownViewModelTests: XCTestCase {

    func test_should_show_returns_false_if_no_known_readers() {

        // TODO - we need to pass in a known readers provider LOL

        let mockStoresManager = MockKnownReadersStoresManager(
            knownReaderIDs: [],
            connectedReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: #function)
        let _ = CardReaderSettingsKnownViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isFalse)
            expectation.fulfill()
        } )

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_should_show_returns_true_if_known_but_no_connected_readers() {

        // TODO - we need to pass in a known readers provider LOL

        let mockStoresManager = MockKnownReadersStoresManager(
            knownReaderIDs: [TestConstants.mockReaderID],
            connectedReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: #function)
        let _ = CardReaderSettingsKnownViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isTrue)
            expectation.fulfill()
        } )

        wait(for: [expectation], timeout: Constants.expectationTimeout)    }

    func test_should_show_returns_false_if_reader_connected() {
    }

    func test_dispatches_connect_on_discovering_known_reader() {
    }

    func test_advances_to_found_unknown_reader_on_discovering_unknown_reader() {

    }
}
