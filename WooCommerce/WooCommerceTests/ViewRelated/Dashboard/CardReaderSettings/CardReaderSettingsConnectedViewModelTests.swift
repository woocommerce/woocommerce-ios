import XCTest
import Hardware
@testable import Yosemite
@testable import WooCommerce

final class CardReaderSettingsConnectedViewModelTests: XCTestCase {
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

    func test_did_change_should_show_returns_false_if_no_connected_readers() {
        let mockCardReaderService = MockCardReaderService()
        ServiceLocator.setCardReader(mockCardReaderService)

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
        let mockCardReaderService = MockCardReaderService()
        mockCardReaderService.connectedReadersSubject.send([MockCardReader.bbposChipper2XBT()])
        ServiceLocator.setCardReader(mockCardReaderService)

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
