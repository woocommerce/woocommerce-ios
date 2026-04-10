import Foundation
import Testing
@testable import Networking

struct BackgroundCatalogDownloadCoordinatorTests {
    private let testDefaults: UserDefaults

    init() {
        // Create isolated UserDefaults suite for this test
        testDefaults = UserDefaults(suiteName: "BackgroundCatalogDownloadCoordinatorTests.\(UUID().uuidString)")!
        BackgroundDownloadState.configure(userDefaults: testDefaults)
    }

    @Test func handleBackgroundSessionEvent_loads_saved_state() async {
        // Given
        let sessionIdentifier = "com.woocommerce.pos.catalog.download.123"
        let siteID: Int64 = 456
        let state = BackgroundDownloadState(
            sessionIdentifier: sessionIdentifier,
            siteID: siteID
        )
        BackgroundDownloadState.save(state)

        let mockDownloader = MockBackgroundDownloader()
        mockDownloader.mockFileURL = URL(fileURLWithPath: "/tmp/test.json")
        let coordinator = BackgroundCatalogDownloadCoordinator(backgroundDownloader: mockDownloader)

        var parsedSiteID: Int64?
        var parsedFileURL: URL?

        // When
        await coordinator.handleBackgroundSessionEvent(
            sessionIdentifier: sessionIdentifier,
            completionHandler: { },
            parseHandler: { fileURL, siteID in
                parsedFileURL = fileURL
                parsedSiteID = siteID
            }
        )

        // Then
        #expect(parsedSiteID == siteID)
        #expect(parsedFileURL?.path == "/tmp/test.json")
    }

    @Test func handleBackgroundSessionEvent_calls_completion_handler_when_no_state() async {
        // Given
        let sessionIdentifier = "com.woocommerce.pos.catalog.download.999"
        let mockDownloader = MockBackgroundDownloader()
        let coordinator = BackgroundCatalogDownloadCoordinator(backgroundDownloader: mockDownloader)

        var completionCalled = false
        var parseCalled = false

        // When
        await coordinator.handleBackgroundSessionEvent(
            sessionIdentifier: sessionIdentifier,
            completionHandler: {
                completionCalled = true
            },
            parseHandler: { _, _ in
                parseCalled = true
            }
        )

        // Then
        #expect(completionCalled == true)
        #expect(parseCalled == false) // Should not parse without state
    }

    @Test func handleBackgroundSessionEvent_clears_state_after_processing() async {
        // Given
        let sessionIdentifier = "com.woocommerce.pos.catalog.download.789"
        let state = BackgroundDownloadState(
            sessionIdentifier: sessionIdentifier,
            siteID: 111
        )
        BackgroundDownloadState.save(state)

        let mockDownloader = MockBackgroundDownloader()
        mockDownloader.mockFileURL = URL(fileURLWithPath: "/tmp/test.json")
        let coordinator = BackgroundCatalogDownloadCoordinator(backgroundDownloader: mockDownloader)

        // When
        await coordinator.handleBackgroundSessionEvent(
            sessionIdentifier: sessionIdentifier,
            completionHandler: { },
            parseHandler: { _, _ in }
        )

        // Then - state should be cleared
        let loadedState = BackgroundDownloadState.load(for: sessionIdentifier)
        #expect(loadedState == nil)
    }

    @Test func handleBackgroundSessionEvent_reconnects_to_session() async {
        // Given
        let sessionIdentifier = "com.woocommerce.pos.catalog.download.reconnect"
        let state = BackgroundDownloadState(
            sessionIdentifier: sessionIdentifier,
            siteID: 222
        )
        BackgroundDownloadState.save(state)

        let mockDownloader = MockBackgroundDownloader()
        mockDownloader.mockFileURL = URL(fileURLWithPath: "/tmp/catalog.json")
        let coordinator = BackgroundCatalogDownloadCoordinator(backgroundDownloader: mockDownloader)

        // When
        await coordinator.handleBackgroundSessionEvent(
            sessionIdentifier: sessionIdentifier,
            completionHandler: { },
            parseHandler: { _, _ in }
        )

        // Then
        #expect(mockDownloader.reconnectSessionCallCount == 1)
        #expect(mockDownloader.lastReconnectSessionIdentifier == sessionIdentifier)
    }
}
