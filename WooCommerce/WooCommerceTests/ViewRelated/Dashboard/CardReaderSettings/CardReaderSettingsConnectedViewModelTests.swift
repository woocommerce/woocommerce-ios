import XCTest
import Combine
import Hardware
@testable import Yosemite
@testable import WooCommerce

final class CardReaderSettingsConnectedViewModelTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        ServiceLocator.setConnectedReaders(nil)
    }

    func test_did_change_should_show_returns_false_if_no_connected_readers() {
        ServiceLocator.setConnectedReaders(
            Empty(completeImmediately: false)
                .prepend([])
                .eraseToAnyPublisher()
        )

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            knownReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: "Check shouldShow returns isFalse")
        let _ = CardReaderSettingsConnectedViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isFalse)
            expectation.fulfill()
        } )

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_did_change_should_show_returns_true_if_a_reader_is_connected() {
        ServiceLocator.setConnectedReaders(
            Empty(completeImmediately: false)
                .prepend([MockCardReader.bbposChipper2XBT()])
                .eraseToAnyPublisher()
        )

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            knownReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: "Check shouldShow returns isTrue")

        let _ = CardReaderSettingsConnectedViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isTrue)
            expectation.fulfill()
        } )

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
