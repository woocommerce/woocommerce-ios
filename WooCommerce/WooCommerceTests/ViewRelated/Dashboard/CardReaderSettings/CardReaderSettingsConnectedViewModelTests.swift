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

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil,
                                                         delayToShowUpdateSuccessMessage: .milliseconds(1))
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
        },
                                                     delayToShowUpdateSuccessMessage: .milliseconds(1))

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_did_change_should_show_returns_true_if_a_reader_is_connected() {
        let expectation = self.expectation(description: #function)

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isTrue)
            expectation.fulfill()
        },
                                                         delayToShowUpdateSuccessMessage: .milliseconds(1))

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

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil,
                                                         delayToShowUpdateSuccessMessage: .milliseconds(1))
        XCTAssertEqual(viewModel.connectedReaderBatteryLevel, "Unknown Battery Level")
    }

    func test_view_model_correctly_formats_connected_card_reader_software_version() {
        let viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil,
                                                             delayToShowUpdateSuccessMessage: .milliseconds(1))
        XCTAssertEqual(viewModel.connectedReaderSoftwareVersion, "Version: 1.00.03.34-SZZZ_Generic_v45-300001")
    }

    func test_view_model_correctly_formats_connected_card_reader_software_version_when_nil() {
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBTNoVerNoBatt()],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil,
                                                         delayToShowUpdateSuccessMessage: .milliseconds(1))
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

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil,
                                                         delayToShowUpdateSuccessMessage: .milliseconds(1))

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

    func test_startCardReaderUpdate_viewModel_logs_tracks_event_cardReaderSoftwareUpdateTapped() {
        // Given

        // When
        viewModel.startCardReaderUpdate()

        // Then
        XCTAssert(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateTapped.rawValue))
    }

    func test_card_reader_update_starts_viewModel_logs_tracks_event_cardReaderSoftwareUpdateStarted() {
        // Given
        // .available not sent

        // When
        mockStoresManager.simulateUpdateStarted()

        // Then
        XCTAssert(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateStarted.rawValue))
        XCTAssert(analytics.receivedProperties.contains(where: {
            $0["software_update_type"] as? String == "Required"
        }))
    }

    func test_optional_card_reader_update_starts_viewModel_logs_tracks_event_cardReaderSoftwareUpdateStarted_with_optional() {
        // Given
        mockStoresManager.simulateOptionalUpdateAvailable()

        // When
        mockStoresManager.simulateUpdateStarted()

        // Then
        XCTAssert(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateStarted.rawValue))
        XCTAssert(analytics.receivedProperties.contains(where: {
            $0["software_update_type"] as? String == "Optional"
        }))
    }

    func test_when_store_sends_update_complete_viewModel_logs_tracks_event_cardReaderSoftwareUpdateSuccess() {
        // Given

        // When
        mockStoresManager.simulateSuccessfulUpdate()

        // Then
        XCTAssert(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateSuccess.rawValue))
    }

    func test_when_store_sends_update_failed_viewModel_logs_tracks_event_cardReaderSoftwareUpdateFailed() {
        // Given
        // .available not sent

        // When
        let expectedError = CardReaderServiceError.softwareUpdate(underlyingError: .readerSoftwareUpdateFailedBatteryLow,
                                                                  batteryLevel: 0.4)
        mockStoresManager.simulateFailedUpdate(error: expectedError)

        // Then
        let expectedErrorDescription = "Hardware.CardReaderServiceError.softwareUpdate(underlyingError: " +
            "Hardware.UnderlyingError.readerSoftwareUpdateFailedBatteryLow, batteryLevel: Optional(0.4))"
        XCTAssert(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateFailed.rawValue))
        XCTAssert(analytics.receivedProperties.contains(where: {
            $0["software_update_type"] as? String == "Required"
        }))
        XCTAssert(analytics.receivedProperties.contains(where: {
            $0[MockAnalyticsProvider.WooAnalyticsKeys.errorKeyDescription] as? String == expectedErrorDescription
        }))
    }

    func test_when_user_cancels_update_viewModel_logs_tracks_event_cardReaderSoftwareUpdateCancelTapped() {
        // Given

        // When
        viewModel.cancelCardReaderUpdate()

        // Then
        XCTAssert(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateCancelTapped.rawValue))
    }

    func test_when_update_is_successfully_canceled_viewModel_logs_tracks_event_cardReaderSoftwareUpdateCanceled() {
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

    func test_when_update_is_successfully_canceled_viewModel_does_not_log_tracks_event_cardReaderSoftwareUpdateFailed() {
        // Given
        let expectation = self.expectation(description: #function)

        mockStoresManager.simulateCancelableUpdate {
            expectation.fulfill()
        }

        // When
        viewModel.cancelCardReaderUpdate()

        // Then
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        XCTAssertFalse(analytics.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateFailed.rawValue))
    }

    func test_when_a_mandatory_update_succeeds_optional_updates_are_not_available() {
        // Given
        // .available is not sent
        mockStoresManager.simulateUpdateStarted()
        let expectation = self.expectation(description: #function)
        viewModel.didUpdate = { [weak self] in
            if self?.viewModel.readerUpdateProgress == nil { //ensures that we wait until completeCardReaderUpdate()
                expectation.fulfill()
            }
        }

        // When
        mockStoresManager.simulateSuccessfulUpdate()

        // Then
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        XCTAssertFalse(viewModel.optionalReaderUpdateAvailable)
    }

    func test_when_an_optional_update_succeeds_optional_updates_are_not_available() {
        // Given
        mockStoresManager.simulateOptionalUpdateAvailable()
        mockStoresManager.simulateUpdateStarted()
        let expectation = self.expectation(description: #function)
        viewModel.didUpdate = { [weak self] in
            if self?.viewModel.readerUpdateProgress == nil { //ensures that we wait until completeCardReaderUpdate()
                expectation.fulfill()
            }
        }

        // When
        mockStoresManager.simulateSuccessfulUpdate()

        // Then
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        XCTAssertFalse(viewModel.optionalReaderUpdateAvailable)
    }

    func test_when_a_mandatory_update_fails_optional_updates_are_not_available() {
        // Given
        // .available is not sent
        mockStoresManager.simulateUpdateStarted()

        // When
        mockStoresManager.simulateFailedUpdate(error: CardReaderServiceError.bluetoothDenied)

        // Then
        XCTAssertFalse(viewModel.optionalReaderUpdateAvailable)
    }

    func test_when_an_optional_update_fails_optional_updates_are_available() {
        // Given
        mockStoresManager.simulateOptionalUpdateAvailable()
        mockStoresManager.simulateUpdateStarted()

        // When
        mockStoresManager.simulateFailedUpdate(error: CardReaderServiceError.bluetoothDenied)

        // Then
        XCTAssertTrue(viewModel.optionalReaderUpdateAvailable)
    }
}
