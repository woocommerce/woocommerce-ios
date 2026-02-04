import XCTest
@testable import Yosemite
@testable import WooCommerce

private struct TestConstants {
    static let mockReaderID = "CHB204909005931"
    static let mockConfiguration = CardPresentPaymentsConfiguration(country: .US)
}

final class CardReaderSettingsSearchingViewModelTests: XCTestCase {

    func test_did_change_should_show_returns_true_if_no_connected_readers() {
        let mockKnownReaderProvider = MockKnownReaderProvider()

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: #function)
        let _ = CardReaderSettingsSearchingViewModel(
            didChangeShouldShow: { shouldShow in
                XCTAssertTrue(shouldShow == .isTrue)
                expectation.fulfill()
            }, knownReaderProvider: mockKnownReaderProvider,
            configuration: TestConstants.mockConfiguration,
            cardReaderConnectionAnalyticsTracker: .init(configuration: TestConstants.mockConfiguration,
                                                        siteID: 0,
                                                        connectionType: .userInitiated,
                                                        stores: mockStoresManager))

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_did_change_should_show_returns_false_if_reader_connected() {
        let mockKnownReaderProvider = MockKnownReaderProvider(knownReader: TestConstants.mockReaderID)

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [MockCardReader.bbposChipper2XBT()],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let expectation = self.expectation(description: #function)

        let _ = CardReaderSettingsSearchingViewModel(
            didChangeShouldShow: { shouldShow in
                XCTAssertTrue(shouldShow == .isFalse)
                expectation.fulfill()
            }, knownReaderProvider: mockKnownReaderProvider,
            configuration: TestConstants.mockConfiguration,
            cardReaderConnectionAnalyticsTracker: .init(configuration: TestConstants.mockConfiguration,
                                                        siteID: 0,
                                                        connectionType: .userInitiated,
                                                        stores: mockStoresManager))

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - Skip Auto Search Tests

    func test_shouldSkipAutoSearch_returns_true_when_reconnection_is_cancelled() {
        let mockKnownReaderProvider = MockKnownReaderProvider()

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let viewModel = CardReaderSettingsSearchingViewModel(
            didChangeShouldShow: nil,
            knownReaderProvider: mockKnownReaderProvider,
            configuration: TestConstants.mockConfiguration,
            cardReaderConnectionAnalyticsTracker: .init(configuration: TestConstants.mockConfiguration,
                                                        siteID: 0,
                                                        connectionType: .userInitiated,
                                                        stores: mockStoresManager))

        // Simulate reconnection starting then becoming idle (cancelled)
        mockStoresManager.simulateReconnecting(reader: MockCardReader.bbposChipper2XBT())
        mockStoresManager.simulateReconnectionIdle()

        XCTAssertTrue(viewModel.shouldSkipAutoSearch())
    }

    func test_shouldSkipAutoSearch_returns_false_when_reconnection_succeeds() {
        let mockKnownReaderProvider = MockKnownReaderProvider()

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let viewModel = CardReaderSettingsSearchingViewModel(
            didChangeShouldShow: nil,
            knownReaderProvider: mockKnownReaderProvider,
            configuration: TestConstants.mockConfiguration,
            cardReaderConnectionAnalyticsTracker: .init(configuration: TestConstants.mockConfiguration,
                                                        siteID: 0,
                                                        connectionType: .userInitiated,
                                                        stores: mockStoresManager))

        // Simulate reconnection starting then succeeding
        mockStoresManager.simulateReconnecting(reader: MockCardReader.bbposChipper2XBT())
        mockStoresManager.simulateReconnectionSucceeded()

        XCTAssertFalse(viewModel.shouldSkipAutoSearch())
    }

    func test_shouldSkipAutoSearch_returns_false_after_clearSkipAutoSearch_is_called() {
        let mockKnownReaderProvider = MockKnownReaderProvider()

        let mockStoresManager = MockCardPresentPaymentsStoresManager(
            connectedReaders: [],
            discoveredReaders: [],
            sessionManager: SessionManager.testingInstance
        )
        ServiceLocator.setStores(mockStoresManager)

        let viewModel = CardReaderSettingsSearchingViewModel(
            didChangeShouldShow: nil,
            knownReaderProvider: mockKnownReaderProvider,
            configuration: TestConstants.mockConfiguration,
            cardReaderConnectionAnalyticsTracker: .init(configuration: TestConstants.mockConfiguration,
                                                        siteID: 0,
                                                        connectionType: .userInitiated,
                                                        stores: mockStoresManager))

        // Simulate reconnection cancelled (sets skip flag)
        mockStoresManager.simulateReconnecting(reader: MockCardReader.bbposChipper2XBT())
        mockStoresManager.simulateReconnectionIdle()
        XCTAssertTrue(viewModel.shouldSkipAutoSearch())

        // Clear the skip flag (simulates user tapping Connect button)
        viewModel.clearSkipAutoSearch()

        XCTAssertFalse(viewModel.shouldSkipAutoSearch())
    }
}
