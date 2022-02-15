import XCTest
@testable import Yosemite
@testable import WooCommerce

final class CardReaderSettingsConnectedViewModelTests: XCTestCase {
    private var mockStoresManager: MockCardPresentPaymentsStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!

    private var viewModel: CardReaderSettingsConnectedViewModel!

    override func setUpWithError() throws {
        mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        analyticsProvider = MockAnalyticsProvider()
        ServiceLocator.setAnalytics(WooAnalytics(analyticsProvider: analyticsProvider))

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
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateTapped.rawValue))
        XCTAssertEqual(
            analyticsProvider.receivedProperties.first?[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String,
            WooAnalyticsEvent.InPersonPayments.unknownGatewayID
        )
    }

    func test_card_reader_update_starts_viewModel_logs_tracks_event_cardReaderSoftwareUpdateStarted() {
        // Given
        // .available not sent

        // When
        mockStoresManager.simulateUpdateStarted()

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateStarted.rawValue))
        XCTAssert(analyticsProvider.receivedProperties.contains(where: {
            $0["software_update_type"] as? String == "Required"
        }))
        XCTAssertEqual(
            analyticsProvider.receivedProperties.first?[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String,
            WooAnalyticsEvent.InPersonPayments.unknownGatewayID
        )
    }

    func test_optional_card_reader_update_starts_viewModel_logs_tracks_event_cardReaderSoftwareUpdateStarted_with_optional() {
        // Given
        mockStoresManager.simulateOptionalUpdateAvailable()

        // When
        mockStoresManager.simulateUpdateStarted()

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateStarted.rawValue))
        XCTAssert(analyticsProvider.receivedProperties.contains(where: {
            $0["software_update_type"] as? String == "Optional"
        }))
        XCTAssertEqual(
            analyticsProvider.receivedProperties.first?[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String,
            WooAnalyticsEvent.InPersonPayments.unknownGatewayID
        )
    }

    func test_when_store_sends_update_complete_viewModel_logs_tracks_event_cardReaderSoftwareUpdateSuccess() {
        // Given

        // When
        mockStoresManager.simulateSuccessfulUpdate()

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateSuccess.rawValue))
        XCTAssertEqual(
            analyticsProvider.receivedProperties.first?[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String,
            WooAnalyticsEvent.InPersonPayments.unknownGatewayID
        )
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
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateFailed.rawValue))
        XCTAssert(analyticsProvider.receivedProperties.contains(where: {
            $0["software_update_type"] as? String == "Required"
        }))
        XCTAssert(analyticsProvider.receivedProperties.contains(where: {
            $0[MockAnalyticsProvider.WooAnalyticsKeys.errorKeyDescription] as? String == expectedErrorDescription
        }))
        XCTAssertEqual(
            analyticsProvider.receivedProperties.first?[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String,
            WooAnalyticsEvent.InPersonPayments.unknownGatewayID
        )
    }

    func test_when_user_cancels_update_viewModel_logs_tracks_event_cardReaderSoftwareUpdateCancelTapped() {
        // Given
        mockStoresManager.simulateCancelableUpdate(onCancel: {})

        // When
        viewModel.cancelCardReaderUpdate?()

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateCancelTapped.rawValue))
        XCTAssertEqual(
            analyticsProvider.receivedProperties.first?[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String,
            WooAnalyticsEvent.InPersonPayments.unknownGatewayID
        )
    }

    func test_when_update_is_successfully_canceled_viewModel_logs_tracks_event_cardReaderSoftwareUpdateCanceled() {
        // Given
        let expectation = self.expectation(description: #function)

        mockStoresManager.simulateCancelableUpdate {
            expectation.fulfill()
        }

        // When
        viewModel.cancelCardReaderUpdate?()

        // Then
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateCanceled.rawValue))
        XCTAssertEqual(
            analyticsProvider.receivedProperties.first?[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String,
            WooAnalyticsEvent.InPersonPayments.unknownGatewayID
        )
    }

    func test_when_update_is_successfully_canceled_viewModel_does_not_log_tracks_event_cardReaderSoftwareUpdateFailed() {
        // Given
        let expectation = self.expectation(description: #function)

        mockStoresManager.simulateCancelableUpdate {
            expectation.fulfill()
        }

        // When
        viewModel.cancelCardReaderUpdate?()

        // Then
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateFailed.rawValue))
    }

    func test_when_update_reaches_100_percent_viewModel_does_not_provide_cancel_handler_so_cancel_button_is_not_shown() {
        // Given
        mockStoresManager.simulateCancelableUpdate(onCancel: {})
        mockStoresManager.simulateUpdateProgress(1)

        // When
        let handler: ()? = viewModel.cancelCardReaderUpdate?()

        // Then
        XCTAssertNil(handler)
    }

    func test_When_update_progress_is_displayed_rounded_to_100_percent_viewModel_does_not_provide_cancel_handler_so_cancel_button_is_not_shown() {
        // Given
        mockStoresManager.simulateCancelableUpdate(onCancel: {})
        mockStoresManager.simulateUpdateProgress(0.995)

        // When
        let handler: ()? = viewModel.cancelCardReaderUpdate?()

        // Then
        XCTAssertNil(handler)
    }

    func test_when_update_reaches_99_percent_viewModel_provides_cancel_handler_so_cancel_button_is_shown() {
        // Given
        mockStoresManager.simulateCancelableUpdate(onCancel: {})
        mockStoresManager.simulateUpdateProgress(0.994)

        // When
        let handler: ()? = viewModel.cancelCardReaderUpdate?()

        // Then
        XCTAssertNotNil(handler)
    }

    func test_when_update_starts_viewModel_test_when_update_reaches_100_percent_viewModel_does_not_provide_cancel_handler_so_cancel_button_is_not_shown() {
        // Given
        mockStoresManager.simulateCancelableUpdate(onCancel: {})

        // When
        let handler: ()? = viewModel.cancelCardReaderUpdate?()

        // Then
        XCTAssertNotNil(handler)
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
