import XCTest
@testable import Yosemite
@testable import WooCommerce

final class CardReaderSettingsConnectedViewModelTests: XCTestCase {
    private var mockStoresManager: MockCardPresentPaymentsStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analyticsTracker: CardReaderConnectionAnalyticsTracker!

    private var viewModel: CardReaderSettingsConnectedViewModel!

    override func setUpWithError() throws {
        mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        ServiceLocator.setAnalytics(analytics)

        analyticsTracker = CardReaderConnectionAnalyticsTracker(configuration: Mocks.configuration,
                                                                stores: mockStoresManager,
                                                                analytics: analytics)
        analyticsTracker.setCandidateReader(MockCardReader.wisePad3())

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil,
                                                         configuration: Mocks.configuration,
                                                         analyticsTracker: analyticsTracker,
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
                                                     configuration: Mocks.configuration,
                                                     analyticsTracker: .init(configuration: Mocks.configuration,
                                                                             stores: mockStoresManager),
                                                     delayToShowUpdateSuccessMessage: .milliseconds(1))

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_did_change_should_show_returns_true_if_a_reader_is_connected() {
        let expectation = self.expectation(description: #function)

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isTrue)
            expectation.fulfill()
        },
                                                         configuration: Mocks.configuration,
                                                         analyticsTracker: .init(configuration: Mocks.configuration,
                                                                                 stores: mockStoresManager),
                                                         delayToShowUpdateSuccessMessage: .milliseconds(1))

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_view_model_correctly_formats_connected_card_reader_battery_level() {
        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil,
                                                         configuration: Mocks.configuration,
                                                         analyticsTracker: .init(configuration: Mocks.configuration,
                                                                                 stores: mockStoresManager))
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
                                                         configuration: Mocks.configuration,
                                                         analyticsTracker: .init(configuration: Mocks.configuration,
                                                                                 stores: mockStoresManager),
                                                         delayToShowUpdateSuccessMessage: .milliseconds(1))
        XCTAssertEqual(viewModel.connectedReaderBatteryLevel, "Unknown Battery Level")
    }

    func test_view_model_correctly_formats_connected_card_reader_software_version() {
        let viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil,
                                                             configuration: Mocks.configuration,
                                                             analyticsTracker: .init(configuration: Mocks.configuration,
                                                                                     stores: mockStoresManager),
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
                                                         configuration: Mocks.configuration,
                                                         analyticsTracker: .init(configuration: Mocks.configuration,
                                                                                 stores: mockStoresManager),
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
                                                         configuration: Mocks.configuration,
                                                         analyticsTracker: .init(configuration: Mocks.configuration,
                                                                                 stores: mockStoresManager),
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

    func test_startCardReaderUpdate_viewModel_logs_tracks_event_cardReaderSoftwareUpdateTapped() throws {
        // Given

        // When
        viewModel.startCardReaderUpdate()

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateTapped.rawValue))
        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String, WooAnalyticsEvent.InPersonPayments.unknownGatewayID)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.countryCode] as? String, "US")
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.cardReaderModel] as? String,
                       MockCardReader.bbposChipper2XBT().readerType.model)
    }

    func test_starting_card_reader_update_logs_cardReaderSoftwareUpdate_event_after_setting_candidateCardReader() throws {
        // Given
        // .available not sent

        // When
        mockStoresManager.simulateUpdateStarted()

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateStarted.rawValue))
        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String, WooAnalyticsEvent.InPersonPayments.unknownGatewayID)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.countryCode] as? String, "US")
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.cardReaderModel] as? String,
                       MockCardReader.bbposChipper2XBT().readerType.model)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.softwareUpdateType] as? String, "Required")
    }

    func test_optional_card_reader_update_starts_viewModel_logs_cardReaderSoftwareUpdateStarted_event_with_optional_update_type() throws {
        // Given
        mockStoresManager.simulateOptionalUpdateAvailable()

        // When
        mockStoresManager.simulateUpdateStarted()

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateStarted.rawValue))
        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String, WooAnalyticsEvent.InPersonPayments.unknownGatewayID)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.countryCode] as? String, "US")
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.cardReaderModel] as? String,
                       MockCardReader.bbposChipper2XBT().readerType.model)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.softwareUpdateType] as? String, "Optional")
    }

    func test_when_store_sends_update_complete_viewModel_logs_tracks_event_cardReaderSoftwareUpdateSuccess() throws {
        // Given

        // When
        mockStoresManager.simulateSuccessfulUpdate()

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateSuccess.rawValue))
        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String, WooAnalyticsEvent.InPersonPayments.unknownGatewayID)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.countryCode] as? String, "US")
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.cardReaderModel] as? String,
                       MockCardReader.bbposChipper2XBT().readerType.model)
    }

    func test_when_store_sends_update_failed_viewModel_logs_tracks_event_cardReaderSoftwareUpdateFailed() throws {
        // Given
        // .available not sent

        // When
        let expectedError = CardReaderServiceError.softwareUpdate(underlyingError: .readerSoftwareUpdateFailedBatteryLow,
                                                                  batteryLevel: 0.4)
        mockStoresManager.simulateFailedUpdate(error: expectedError)

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateFailed.rawValue))
        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String, WooAnalyticsEvent.InPersonPayments.unknownGatewayID)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.countryCode] as? String, "US")
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.cardReaderModel] as? String,
                       MockCardReader.bbposChipper2XBT().readerType.model)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.softwareUpdateType] as? String, "Required")
        let expectedErrorDescription = "Unable to update card reader software - the reader battery is too low"
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.errorDescription] as? String, expectedErrorDescription)
    }

    func test_when_user_cancels_update_viewModel_logs_tracks_event_cardReaderSoftwareUpdateCancelTapped() throws {
        // Given
        mockStoresManager.simulateCancelableUpdate(onCancel: {})

        // When
        viewModel.cancelCardReaderUpdate?()

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateCancelTapped.rawValue))
        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String, WooAnalyticsEvent.InPersonPayments.unknownGatewayID)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.countryCode] as? String, "US")
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.cardReaderModel] as? String,
                       MockCardReader.bbposChipper2XBT().readerType.model)
    }

    func test_when_update_is_successfully_canceled_viewModel_logs_tracks_event_cardReaderSoftwareUpdateCanceled() throws {
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
        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.gatewayID] as? String, WooAnalyticsEvent.InPersonPayments.unknownGatewayID)
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.countryCode] as? String, "US")
        XCTAssertEqual(firstPropertiesBatch[WooAnalyticsEvent.InPersonPayments.Keys.cardReaderModel] as? String,
                       MockCardReader.bbposChipper2XBT().readerType.model)
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

    func test_starting_card_reader_update_does_not_log_cardReaderSoftwareUpdateStarted_event_without_candidateCardReader() throws {
        // Given
        // .available not sent.
        analyticsTracker.setCandidateReader(nil)

        // When
        mockStoresManager.simulateUpdateStarted()
        viewModel.cancelCardReaderUpdate?()

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderSoftwareUpdateStarted.rawValue))
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

    func test_when_connected_to_one_reader_it_sets_connectedReaderModel() {
        XCTAssertEqual(viewModel.connectedReaderModel, MockCardReader.bbposChipper2XBT().readerType.model)
    }

    func test_when_connected_to_two_readers_it_sets_connectedReaderModel_from_the_first_reader() {
        // Given
        mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.wisePad3(), MockCardReader.bbposChipper2XBT()],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil,
                                                         configuration: Mocks.configuration,
                                                         analyticsTracker: .init(configuration: Mocks.configuration,
                                                                                 stores: mockStoresManager),
                                                         delayToShowUpdateSuccessMessage: .milliseconds(1))

        // Then
        XCTAssertEqual(viewModel.connectedReaderModel, "WISEPAD_3")
    }

    func test_when_not_connected_to_any_readers_it_sets_connectedReaderModel_to_nil() {
        // Given
        mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        viewModel = CardReaderSettingsConnectedViewModel(didChangeShouldShow: nil,
                                                         configuration: Mocks.configuration,
                                                         analyticsTracker: .init(configuration: Mocks.configuration,
                                                                                 stores: mockStoresManager),
                                                         delayToShowUpdateSuccessMessage: .milliseconds(1))

        // Then
        XCTAssertNil(viewModel.connectedReaderModel)
    }
}

private extension CardReaderSettingsConnectedViewModelTests {
    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: "US")
    }
}
