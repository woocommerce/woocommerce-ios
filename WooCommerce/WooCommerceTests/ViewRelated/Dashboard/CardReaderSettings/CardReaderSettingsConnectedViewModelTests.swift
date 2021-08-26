import XCTest
@testable import Yosemite
@testable import WooCommerce

final class CardReaderSettingsConnectedViewModelTests: XCTestCase {

    func test_did_change_should_show_returns_false_if_no_connected_readers() {
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
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
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
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

    func test_checkForCardReaderUpdate_properly_handles_update_available() {
        // Given
        let expectation = self.expectation(description: #function)

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            sessionManager: SessionManager.testingInstance,
            readerUpdateAvailable: true
        )
        ServiceLocator.setStores(mockStoresManager)

        let viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil)

        viewModel.didUpdate = {
            if viewModel.readerUpdateAvailable == .isTrue {
                expectation.fulfill()
            }
        }

        // When
        viewModel.checkForCardReaderUpdate()

        // Then
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_checkForCardReaderUpdate_properly_handles_update_not_available() {
        // Given
        let expectation = self.expectation(description: #function)

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            sessionManager: SessionManager.testingInstance,
            readerUpdateAvailable: false
        )
        ServiceLocator.setStores(mockStoresManager)

        let viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil)

        viewModel.didUpdate = {
            if viewModel.readerUpdateAvailable == .isFalse {
                expectation.fulfill()
            }
        }

        // When
        viewModel.checkForCardReaderUpdate()

        // Then
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_checkForCardReaderUpdate_properly_handles_update_check_failure() {
        // Given
        let expectation = self.expectation(description: #function)

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            sessionManager: SessionManager.testingInstance,
            failReaderUpdateCheck: true
        )
        ServiceLocator.setStores(mockStoresManager)

        let viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil)

        viewModel.didUpdate = {
            if viewModel.readerUpdateAvailable == .isFalse {
                expectation.fulfill()
            }
        }

        // When
        viewModel.checkForCardReaderUpdate()

        // Then
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
