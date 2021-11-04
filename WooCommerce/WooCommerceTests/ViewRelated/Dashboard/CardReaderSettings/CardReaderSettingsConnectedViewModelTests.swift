import XCTest
@testable import Yosemite
@testable import WooCommerce

final class CardReaderSettingsConnectedViewModelTests: XCTestCase {
    private var mockStoresManager: MockCardPresentPaymentsStoresManager!
    private var analytics: MockAnalyticsProvider!

    private var viewModel: CardReaderSettingsConnectedViewModel!

    override func setUpWithError() throws {
        mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        analytics = MockAnalyticsProvider()
        ServiceLocator.setAnalytics(WooAnalytics(analyticsProvider: analytics))

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil)
    }

    func test_did_change_should_show_returns_false_if_no_connected_readers() {
        mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: #function)
        let _ = CardReaderSettingsConnectedViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isFalse)
            expectation.fulfill()
        } )

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_did_change_should_show_returns_true_if_a_reader_is_connected() {
        let expectation = self.expectation(description: #function)

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isTrue)
            expectation.fulfill()
        } )

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_view_model_correctly_formats_connected_card_reader_battery_level() {
        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil)
        XCTAssertEqual(viewModel.connectedReaderBatteryLevel, "50% Battery")
    }

    func test_view_model_correctly_formats_connected_card_reader_battery_level_when_nil() {
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBTNoVerNoBatt()],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil)
        XCTAssertEqual(viewModel.connectedReaderBatteryLevel, "Unknown Battery Level")
    }

    func test_view_model_correctly_formats_connected_card_reader_software_version() {
        let viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil)
        XCTAssertEqual(viewModel.connectedReaderSoftwareVersion, "Version: 1.00.03.34-SZZZ_Generic_v45-300001")
    }

    func test_view_model_correctly_formats_connected_card_reader_software_version_when_nil() {
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBTNoVerNoBatt()],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil)
        XCTAssertEqual(viewModel.connectedReaderSoftwareVersion, "Unknown Software Version")
    }

    func test_startCardReaderUpdate_properly_handles_successful_update() {
        // Given
        let expectation = self.expectation(description: #function)

        var updateDidBegin = false

        viewModel.didUpdate = {
            if self.viewModel.readerUpdateInProgress {
                updateDidBegin = true
            }

            // Update began
            if updateDidBegin {
                // But now it has stopped
                if !self.viewModel.readerUpdateInProgress {
                    expectation.fulfill()
                }
            }
        }


        // When
        viewModel.startCardReaderUpdate()

        // Then
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_startCardReaderUpdate_properly_handles_update_failure() {
        // Given
        let expectation = self.expectation(description: #function)

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance,
            failUpdate: true
        )
        ServiceLocator.setStores(mockStoresManager)

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil)

        var updateDidBegin = false

        viewModel.didUpdate = {
            if self.viewModel.readerUpdateInProgress {
                updateDidBegin = true
            }

            // Update began
            if updateDidBegin {
                // But now it has stopped
                if !self.viewModel.readerUpdateInProgress {
                    expectation.fulfill()
                }
            }
        }

        // When
        viewModel.startCardReaderUpdate()

        // Then
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_startCardReaderUpdate_ViewModel_LogsTracksEvent_cardReaderSoftwareUpdateTapped() {
        // Given

        // When
        viewModel.startCardReaderUpdate()

        // Then
        XCTAssert(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateTapped.rawValue))
    }

    func test_startCardReaderUpdate_ViewModel_LogsTracksEvent_cardReaderSoftwareUpdateStarted() {
        // Given

        // When
        mockStoresManager.simulateUpdateStarted()

        // Then
        XCTAssert(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateStarted.rawValue))
    }

    func test_WhenStoreSendsUpdateComplete_ViewModel_LogsTracksEvent_cardReaderSoftwareUpdateSuccess() {
        // Given

        // When
        mockStoresManager.simulateSuccessfulUpdate()

        // Then
        XCTAssert(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateSuccess.rawValue))
    }

    func test_WhenStoreSendsUpdateFailed_ViewModel_LogsTracksEvent_cardReaderSoftwareUpdateFailed() {
        // Given

        // When
        let expectedError = CardReaderServiceError.softwareUpdate(underlyingError: .readerSoftwareUpdateFailedBatteryLow,
                                                                  batteryLevel: 0.4)
        mockStoresManager.simulateFailedUpdate(error: expectedError)

        // Then
        XCTAssert(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateFailed.rawValue))
    }

    func test_WhenUserCancelsUpdate_ViewModel_LogsTracksEvent_cardReaderSoftwareUpdateCancelTapped() {
        // Given

        // When
        viewModel.cancelCardReaderUpdate()

        // Then
        XCTAssert(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateCancelTapped.rawValue))
    }

    func test_WhenUpdateIsSuccessfullyCanceled_ViewModel_LogsTracksEvent_cardReaderSoftwareUpdateCanceled() {
        // Given
        let expectation = self.expectation(description: #function)

        mockStoresManager.simulateCancelableUpdate {
            expectation.fulfill()
        }

        // When
        viewModel.cancelCardReaderUpdate()

        // Then
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        XCTAssert(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateCanceled.rawValue))
    }
}
