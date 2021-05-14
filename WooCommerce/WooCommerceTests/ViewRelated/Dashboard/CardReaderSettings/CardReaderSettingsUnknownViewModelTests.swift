import XCTest
import Hardware
@testable import Yosemite
@testable import WooCommerce

final class CardReaderSettingsUnknownViewModelTests: XCTestCase {
    var defaultCardReaderService: CardReaderService? = nil

    override func setUp() {
        super.setUp()
        defaultCardReaderService = ServiceLocator.cardReaderService
    }

    override func tearDown() {
        super.tearDown()
        // Force unwrapping this because if we don't restore the reader correctly,
        // some other tests will fail, and it will be much harder to track down the cause.
        ServiceLocator.setCardReader(defaultCardReaderService!)
    }

    func test_did_change_should_show_returns_true_if_no_known_no_connected_readers() {
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            knownReaders: [],
            connectedReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: "Check shouldShow returns isTrue")
        let _ = CardReaderSettingsUnknownViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isTrue)
            expectation.fulfill()
        } )

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_did_change_should_show_returns_false_if_reader_known() {
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            knownReaders: [MockCardReader.bbposChipper2XBT()],
            connectedReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: "Check shouldShow returns isFalse")

        let _ = CardReaderSettingsUnknownViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isFalse)
            expectation.fulfill()
        } )

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_did_change_should_show_returns_false_if_reader_connected() {
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            knownReaders: [],
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: "Check shouldShow returns isFalse")

        let _ = CardReaderSettingsUnknownViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isFalse)
            expectation.fulfill()
        } )

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_did_change_should_show_returns_false_if_reader_known_and_connected() {
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            knownReaders: [MockCardReader.bbposChipper2XBT()],
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: "Check shouldShow returns isFalse")

        let _ = CardReaderSettingsUnknownViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isFalse)
            expectation.fulfill()
        } )

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
