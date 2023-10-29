import XCTest
import Fakes
import Storage
import Yosemite
@testable import WooCommerce

final class CardReaderConnectionControllerTests: XCTestCase {
    // TODO: Work out why these tests fail on CI, but pass locally, then re-enable these in the test plan
    // https://github.com/woocommerce/woocommerce-ios/issues/10536

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    private var storageManager: MockStorageManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()

        let paymentGateway = storageManager.viewStorage.insertNewObject(ofType: StoragePaymentGatewayAccount.self)
        paymentGateway.update(with: .fake().copy(siteID: sampleSiteID, gatewayID: "woocommerce-payments", isCardPresentEligible: true))
        storageManager.viewStorage.saveIfNeeded()


        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        ServiceLocator.setAnalytics(analytics)
    }

    override func tearDown() {
        super.tearDown()
        storageManager = nil
        analytics = nil
        analyticsProvider = nil
    }

    func test_cancelling_search_calls_completion_with_success_false() throws {
        // Given
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance,
            storageManager: storageManager
        )

        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: nil)
        let mockAlerts = MockCardReaderSettingsAlerts(mode: .cancelScanning)

        let controller = CardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: mockStoresManager,
            knownReaderProvider: mockKnownReaderProvider,
            alertsPresenter: MockCardPresentPaymentAlertsPresenter(),
            alertsProvider: mockAlerts,
            configuration: Mocks.configuration,
            analyticsTracker: .init(configuration: Mocks.configuration,
                                    siteID: sampleSiteID,
                                    connectionType: .userInitiated,
                                    stores: mockStoresManager,
                                    analytics: analytics)
        )

        // When
        let connectionResult: CardReaderConnectionResult = waitFor { promise in
            controller.searchAndConnect() { result in
                XCTAssertTrue(result.isSuccess)
                if case .success(let connectionResult) = result {
                    promise(connectionResult)
                }
            }
        }

        // Then
        guard case .canceled(let source) = connectionResult else {
            return XCTFail("Expected connection to be canceled")
        }
        assertEqual(.searchingForReader, source)
    }

    func test_finding_an_unknown_reader_prompts_user_before_completing_with_success_true() {
        // Given
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [MockCardReader.bbposChipper2XBT()],
            sessionManager: SessionManager.testingInstance,
            storageManager: storageManager
        )

        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: nil)
        let mockAlerts = MockCardReaderSettingsAlerts(mode: .connectFoundReader)
        let controller = CardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: mockStoresManager,
            knownReaderProvider: mockKnownReaderProvider,
            alertsPresenter: MockCardPresentPaymentAlertsPresenter(),
            alertsProvider: mockAlerts,
            configuration: Mocks.configuration,
            analyticsTracker: .init(configuration: Mocks.configuration,
                                    siteID: sampleSiteID,
                                    connectionType: .userInitiated,
                                    stores: mockStoresManager,
                                    analytics: analytics)
        )

        // When
        let connectionResult: CardReaderConnectionResult = waitFor { promise in
            controller.searchAndConnect() { result in
                if case .success(let connectionResult) = result {
                    promise(connectionResult)
                }
            }
        }

        // Then
        guard case .connected(let reader) = connectionResult else {
            return XCTFail("Expected reader to be connected")
        }
        assertEqual(MockCardReader.bbposChipper2XBT(), reader)

        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderConnectionSuccess.rawValue))
    }

    func test_finding_an_known_reader_automatically_connects_and_completes_with_success_true() {
        // Given
        let knownReader = MockCardReader.bbposChipper2XBT()

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [knownReader],
            sessionManager: SessionManager.testingInstance,
            storageManager: storageManager
        )

        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: knownReader.id)
        let mockAlerts = MockCardReaderSettingsAlerts(mode: .connectFoundReader)
        let controller = CardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: mockStoresManager,
            knownReaderProvider: mockKnownReaderProvider,
            alertsPresenter: MockCardPresentPaymentAlertsPresenter(),
            alertsProvider: mockAlerts,
            configuration: Mocks.configuration,
            analyticsTracker: .init(configuration: Mocks.configuration,
                                    siteID: sampleSiteID,
                                    connectionType: .userInitiated,
                                    stores: mockStoresManager,
                                    analytics: analytics)
        )

        // When
        let connectionResult: CardReaderConnectionResult = waitFor { promise in
            controller.searchAndConnect() { result in
                if case .success(let connectionResult) = result {
                    promise(connectionResult)
                }
            }
        }

        // Then
        guard case .connected(let reader) = connectionResult else {
            return XCTFail("Expected reader to be connected")
        }
        assertEqual(MockCardReader.bbposChipper2XBT(), reader)
    }

    func test_searching_error_presents_error_to_user_and_completes_with_failure() {
        // Given
        let expectation = self.expectation(description: #function)

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance,
            storageManager: storageManager,
            failDiscovery: true
        )

        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: nil)
        let mockAlerts = MockCardReaderSettingsAlerts(mode: .closeScanFailure)
        let controller = CardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: mockStoresManager,
            knownReaderProvider: mockKnownReaderProvider,
            alertsPresenter: MockCardPresentPaymentAlertsPresenter(),
            alertsProvider: mockAlerts,
            configuration: Mocks.configuration,
            analyticsTracker: .init(configuration: Mocks.configuration,
                                    siteID: sampleSiteID,
                                    connectionType: .userInitiated,
                                    stores: mockStoresManager,
                                    analytics: analytics)
        )

        // When
        controller.searchAndConnect() { result in
            XCTAssertTrue(result.isFailure)
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: Constants.expectationTimeout)
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderDiscoveryFailed.rawValue))
    }

    func test_finding_multiple_readers_presents_list_to_user_and_cancelling_list_calls_completion_with_success_false() {
        // Given
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [MockCardReader.bbposChipper2XBT(), MockCardReader.bbposChipper2XBT()],
            sessionManager: SessionManager.testingInstance,
            storageManager: storageManager
        )

        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: nil)
        let mockAlerts = MockCardReaderSettingsAlerts(mode: .continueSearching)
        let mockAlertPresenter = MockCardPresentPaymentAlertsPresenter(mode: .cancelFoundSeveral)
        let controller = CardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: mockStoresManager,
            knownReaderProvider: mockKnownReaderProvider,
            alertsPresenter: mockAlertPresenter,
            alertsProvider: mockAlerts,
            configuration: Mocks.configuration,
            analyticsTracker: .init(configuration: Mocks.configuration,
                                    siteID: sampleSiteID,
                                    connectionType: .userInitiated,
                                    stores: mockStoresManager,
                                    analytics: analytics)
        )

        // When
        let connectionResult: CardReaderConnectionResult = waitFor { promise in
            controller.searchAndConnect() { result in
                if case .success(let connectionResult) = result {
                    promise(connectionResult)
                }
            }
        }

        // Then
        guard case .canceled(let source) = connectionResult else {
            return XCTFail("Expected connection to be canceled")
        }
        assertEqual(.foundSeveralReaders, source)
    }

    func test_user_can_cancel_search_after_connection_error() {
        // Given
        let discoveredReaders = [MockCardReader.bbposChipper2XBT()]

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: discoveredReaders,
            sessionManager: SessionManager.testingInstance,
            storageManager: storageManager,
            failConnection: true
        )

        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: nil)
        let mockAlerts = MockCardReaderSettingsAlerts(mode: .cancelSearchingAfterConnectionFailure)

        let controller = CardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: mockStoresManager,
            knownReaderProvider: mockKnownReaderProvider,
            alertsPresenter: MockCardPresentPaymentAlertsPresenter(),
            alertsProvider: mockAlerts,
            configuration: Mocks.configuration,
            analyticsTracker: .init(configuration: Mocks.configuration,
                                    siteID: sampleSiteID,
                                    connectionType: .userInitiated,
                                    stores: mockStoresManager,
                                    analytics: analytics)
        )

        // When
        let connectionResult: CardReaderConnectionResult = waitFor { promise in
            controller.searchAndConnect() { result in
                if case .success(let connectionResult) = result {
                    promise(connectionResult)
                }
            }
        }

        // Then
        guard case .canceled(let source) = connectionResult else {
            return XCTFail("Expected connection to be canceled")
        }
        assertEqual(.connectionError, source)

        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardReaderConnectionFailed.rawValue))
    }

    func test_user_can_cancel_search_after_connection_error_due_to_low_battery() {
        // Given
        let discoveredReaders = [MockCardReader.bbposChipper2XBTWithCriticallyLowBattery()]

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: discoveredReaders,
            sessionManager: SessionManager.testingInstance,
            storageManager: storageManager
        )

        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: nil)
        let mockAlerts = MockCardReaderSettingsAlerts(mode: .cancelSearchingAfterConnectionFailure)

        let controller = CardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: mockStoresManager,
            knownReaderProvider: mockKnownReaderProvider,
            alertsPresenter: MockCardPresentPaymentAlertsPresenter(),
            alertsProvider: mockAlerts,
            configuration: Mocks.configuration,
            analyticsTracker: .init(configuration: Mocks.configuration,
                                    siteID: sampleSiteID,
                                    connectionType: .userInitiated,
                                    stores: mockStoresManager,
                                    analytics: analytics)
        )

        // When
        let connectionResult: CardReaderConnectionResult = waitFor { promise in
            controller.searchAndConnect() { result in
                if case .success(let connectionResult) = result {
                    promise(connectionResult)
                }
            }
        }

        // Then
        guard case .canceled(let source) = connectionResult else {
            return XCTFail("Expected connection to be canceled")
        }
        assertEqual(.connectionError, source)
    }

    func test_finding_multiple_readers_presents_list_to_user_and_choosing_one_calls_completion_with_success_true() {
        // Given
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [MockCardReader.bbposChipper2XBT(), MockCardReader.bbposChipper2XBT()],
            sessionManager: SessionManager.testingInstance,
            storageManager: storageManager
        )

        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: nil)
        let mockAlerts = MockCardReaderSettingsAlerts(mode: .continueSearching)
        let mockAlertPresenter = MockCardPresentPaymentAlertsPresenter(mode: .connectFirstFound)

        let controller = CardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: mockStoresManager,
            knownReaderProvider: mockKnownReaderProvider,
            alertsPresenter: mockAlertPresenter,
            alertsProvider: mockAlerts,
            configuration: Mocks.configuration,
            analyticsTracker: .init(configuration: Mocks.configuration,
                                    siteID: sampleSiteID,
                                    connectionType: .userInitiated,
                                    stores: mockStoresManager,
                                    analytics: analytics)
        )

        // When
        let connectionResult: CardReaderConnectionResult = waitFor { promise in
            controller.searchAndConnect() { result in
                if case .success(let connectionResult) = result {
                    promise(connectionResult)
                }
            }
        }

        // Then
        guard case .connected(let reader) = connectionResult else {
            return XCTFail("Expected reader to be connected")
        }
        assertEqual(MockCardReader.bbposChipper2XBT(), reader)
    }

    func test_user_can_continue_search_after_connection_error() {
        // Given
        let discoveredReaders = [MockCardReader.bbposChipper2XBT()]

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: discoveredReaders,
            sessionManager: SessionManager.testingInstance,
            storageManager: storageManager,
            failConnection: true
        )

        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: nil)
        let mockAlerts = MockCardReaderSettingsAlerts(mode: .continueSearchingAfterConnectionFailure)

        let controller = CardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: mockStoresManager,
            knownReaderProvider: mockKnownReaderProvider,
            alertsPresenter: MockCardPresentPaymentAlertsPresenter(),
            alertsProvider: mockAlerts,
            configuration: Mocks.configuration,
            analyticsTracker: .init(configuration: Mocks.configuration,
                                    siteID: sampleSiteID,
                                    connectionType: .userInitiated,
                                    stores: mockStoresManager,
                                    analytics: analytics)
        )

        // When
        let connectionResult: CardReaderConnectionResult = waitFor { promise in
            controller.searchAndConnect() { result in
                if case .success(let connectionResult) = result {
                    promise(connectionResult)
                }
            }
        }

        // Then
        guard case .canceled(let source) = connectionResult else {
            return XCTFail("Expected connection to be canceled")
        }
        assertEqual(.searchingForReader, source)
    }

    func test_user_can_continue_search_after_update_error() {
        // Given
        let discoveredReaders = [MockCardReader.bbposChipper2XBT()]

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: discoveredReaders,
            sessionManager: SessionManager.testingInstance,
            storageManager: storageManager,
            failUpdate: true
        )

        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: nil)
        let mockAlerts = MockCardReaderSettingsAlerts(mode: .continueSearchingAfterConnectionFailure)

        let controller = CardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: mockStoresManager,
            knownReaderProvider: mockKnownReaderProvider,
            alertsPresenter: MockCardPresentPaymentAlertsPresenter(),
            alertsProvider: mockAlerts,
            configuration: Mocks.configuration,
            analyticsTracker: .init(configuration: Mocks.configuration,
                                    siteID: sampleSiteID,
                                    connectionType: .userInitiated,
                                    stores: mockStoresManager,
                                    analytics: analytics)
        )

        // When
        let connectionResult: CardReaderConnectionResult = waitFor { promise in
            controller.searchAndConnect() { result in
                if case .success(let connectionResult) = result {
                    promise(connectionResult)
                }
            }
        }

        // Then
        guard case .canceled(let source) = connectionResult else {
            return XCTFail("Expected connection to be canceled")
        }
        assertEqual(.searchingForReader, source)
    }

    func test_cancelling_connection_calls_completion_with_success_and_canceled() throws {
        // Given
        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [MockCardReader.bbposChipper2XBT()],
            sessionManager: SessionManager.testingInstance,
            storageManager: storageManager
        )

        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: nil)
        let mockAlerts = MockCardReaderSettingsAlerts(mode: .cancelFoundReader)
        let controller = CardReaderConnectionController(
            forSiteID: sampleSiteID,
            storageManager: storageManager,
            stores: mockStoresManager,
            knownReaderProvider: mockKnownReaderProvider,
            alertsPresenter: MockCardPresentPaymentAlertsPresenter(),
            alertsProvider: mockAlerts,
            configuration: Mocks.configuration,
            analyticsTracker: .init(configuration: Mocks.configuration,
                                    siteID: sampleSiteID,
                                    connectionType: .userInitiated,
                                    stores: mockStoresManager,
                                    analytics: analytics)
        )

        // When
        let connectionResult: CardReaderConnectionResult = waitFor(timeout: 6.0) { promise in
            controller.searchAndConnect() { result in
                if case .success(let connectionResult) = result {
                    promise(connectionResult)
                }
            }
        }

        // Then
        guard case .canceled(let source) = connectionResult else {
            return XCTFail("Expected connection to be canceled")
        }
        assertEqual(.foundReader, source)
    }
}

private extension CardReaderConnectionControllerTests {
    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: .US)
    }
}
