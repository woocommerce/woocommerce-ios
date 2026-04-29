import Foundation
import Testing
@testable import Networking

struct BackgroundCatalogDownloadCoordinatorTests {
    private let pendingFileStore: PendingCatalogFileStore
    private let downloadStateStore: BackgroundDownloadStateStore
    private let fileManager: FileManager

    init() {
        let testDefaults = UserDefaults(suiteName: "BackgroundCatalogDownloadCoordinatorTests.\(UUID().uuidString)")!
        pendingFileStore = PendingCatalogFileStore(userDefaults: testDefaults)
        downloadStateStore = BackgroundDownloadStateStore(userDefaults: testDefaults)
        fileManager = .default
    }

    @Test func handleBackgroundSessionEvent_loads_saved_state() async {
        // Given
        let sessionIdentifier = "com.woocommerce.pos.catalog.download.123"
        let siteID: Int64 = 456
        let state = BackgroundDownloadState(
            sessionIdentifier: sessionIdentifier,
            siteID: siteID
        )
        downloadStateStore.save(state)

        let mockDownloader = MockBackgroundDownloader()
        mockDownloader.mockFileURL = URL(fileURLWithPath: "/tmp/test.json")
        let coordinator = makeCoordinator(downloader: mockDownloader)

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
        let coordinator = makeCoordinator(downloader: mockDownloader)

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
        downloadStateStore.save(state)

        let mockDownloader = MockBackgroundDownloader()
        mockDownloader.mockFileURL = URL(fileURLWithPath: "/tmp/test.json")
        let coordinator = makeCoordinator(downloader: mockDownloader)

        // When
        await coordinator.handleBackgroundSessionEvent(
            sessionIdentifier: sessionIdentifier,
            completionHandler: { },
            parseHandler: { _, _ in }
        )

        // Then - state should be cleared
        let loadedState = downloadStateStore.load(for: sessionIdentifier)
        #expect(loadedState == nil)
    }

    @Test func handleBackgroundSessionEvent_reconnects_to_session() async {
        // Given
        let sessionIdentifier = "com.woocommerce.pos.catalog.download.reconnect"
        let state = BackgroundDownloadState(
            sessionIdentifier: sessionIdentifier,
            siteID: 222
        )
        downloadStateStore.save(state)

        let mockDownloader = MockBackgroundDownloader()
        mockDownloader.mockFileURL = URL(fileURLWithPath: "/tmp/catalog.json")
        let coordinator = makeCoordinator(downloader: mockDownloader)

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

    @Test func handleBackgroundSessionEvent_when_parse_succeeds_then_clears_all_state_and_deletes_file() async throws {
        // Given
        let sessionIdentifier = "com.woocommerce.pos.catalog.download.ok"
        let siteID: Int64 = 111
        downloadStateStore.save(.init(sessionIdentifier: sessionIdentifier, siteID: siteID))

        let downloadedFile = try makeDownloadedFile(named: "catalog.json")
        let mockDownloader = MockBackgroundDownloader()
        mockDownloader.mockFileURL = downloadedFile
        let coordinator = makeCoordinator(downloader: mockDownloader)

        var stagedPath: String?

        // When
        await coordinator.handleBackgroundSessionEvent(
            sessionIdentifier: sessionIdentifier,
            completionHandler: { },
            parseHandler: { url, _ in
                stagedPath = url.path
            }
        )

        // Then
        #expect(downloadStateStore.load(for: sessionIdentifier) == nil)
        #expect(pendingFileStore.load() == nil)
        if let stagedPath {
            #expect(fileManager.fileExists(atPath: stagedPath) == false)
        }
    }

    @Test func handleBackgroundSessionEvent_when_parse_throws_then_leaves_staged_file_and_pending_record() async throws {
        // Given
        let sessionIdentifier = "com.woocommerce.pos.catalog.download.fail"
        let siteID: Int64 = 222
        downloadStateStore.save(.init(sessionIdentifier: sessionIdentifier, siteID: siteID))

        let downloadedFile = try makeDownloadedFile(named: "catalog.json")
        let mockDownloader = MockBackgroundDownloader()
        mockDownloader.mockFileURL = downloadedFile
        let coordinator = makeCoordinator(downloader: mockDownloader)

        struct ParseError: Error {}
        var stagedPath: String?

        // When
        await coordinator.handleBackgroundSessionEvent(
            sessionIdentifier: sessionIdentifier,
            completionHandler: { },
            parseHandler: { url, _ in
                stagedPath = url.path
                throw ParseError()
            }
        )

        // Then
        #expect(downloadStateStore.load(for: sessionIdentifier) == nil) // session state always cleared
        let pending = try #require(pendingFileStore.load())
        #expect(pending.siteID == siteID)
        let staged = try #require(stagedPath)
        #expect(pending.filePath == staged)
        #expect(fileManager.fileExists(atPath: staged) == true)

        // Cleanup
        try? fileManager.removeItem(atPath: staged)
    }

    @Test func resumePendingDownloadIfNeeded_when_no_pending_record_then_does_nothing() async {
        // Given
        pendingFileStore.clear()
        let coordinator = makeCoordinator(downloader: MockBackgroundDownloader())

        var parseCalled = false

        // When
        await coordinator.resumePendingDownloadIfNeeded { _, _ in
            parseCalled = true
        }

        // Then
        #expect(parseCalled == false)
    }

    @Test func resumePendingDownloadIfNeeded_when_pending_record_but_file_missing_then_clears_record() async {
        // Given
        pendingFileStore.save(.init(filePath: "/does/not/exist/catalog.json", siteID: 333))
        let coordinator = makeCoordinator(downloader: MockBackgroundDownloader())

        var parseCalled = false

        // When
        await coordinator.resumePendingDownloadIfNeeded { _, _ in
            parseCalled = true
        }

        // Then
        #expect(parseCalled == false)
        #expect(pendingFileStore.load() == nil)
    }

    @Test func resumePendingDownloadIfNeeded_when_file_exists_and_parse_succeeds_then_deletes_file_and_clears_record() async throws {
        // Given
        let downloadedFile = try makeDownloadedFile(named: "pending.json")
        pendingFileStore.save(.init(filePath: downloadedFile.path, siteID: 444))
        let coordinator = makeCoordinator(downloader: MockBackgroundDownloader())

        var parsedSiteID: Int64?

        // When
        await coordinator.resumePendingDownloadIfNeeded { url, siteID in
            #expect(url.path == downloadedFile.path)
            parsedSiteID = siteID
        }

        // Then
        #expect(parsedSiteID == 444)
        #expect(pendingFileStore.load() == nil)
        #expect(fileManager.fileExists(atPath: downloadedFile.path) == false)
    }

    @Test func resumePendingDownloadIfNeeded_when_parse_throws_then_leaves_file_for_next_retry() async throws {
        // Given
        let downloadedFile = try makeDownloadedFile(named: "pending.json")
        pendingFileStore.save(.init(filePath: downloadedFile.path, siteID: 555))
        let coordinator = makeCoordinator(downloader: MockBackgroundDownloader())

        struct ParseError: Error {}

        // When
        await coordinator.resumePendingDownloadIfNeeded { _, _ in
            throw ParseError()
        }

        // Then
        let pending = try #require(pendingFileStore.load())
        #expect(pending.filePath == downloadedFile.path)
        #expect(fileManager.fileExists(atPath: downloadedFile.path) == true)

        // Cleanup
        try? fileManager.removeItem(at: downloadedFile)
    }

    // MARK: - PendingCatalogFile round-trips

    @Suite
    struct PendingCatalogFileStorage {
        private let store: PendingCatalogFileStore

        init() {
            let testDefaults = UserDefaults(suiteName: "PendingCatalogFileStorage.\(UUID().uuidString)")!
            store = PendingCatalogFileStore(userDefaults: testDefaults)
        }

        @Test func save_then_load_round_trips_the_value() {
            // Given
            let pending = PendingCatalogFile(filePath: "/tmp/catalog.json", siteID: 42)

            // When
            store.save(pending)
            let loaded = store.load()

            // Then
            #expect(loaded?.filePath == "/tmp/catalog.json")
            #expect(loaded?.siteID == 42)
        }

        @Test func clear_removes_the_stored_value() {
            // Given
            store.save(.init(filePath: "/tmp/x", siteID: 1))

            // When
            store.clear()

            // Then
            #expect(store.load() == nil)
        }

        @Test func load_returns_nil_when_nothing_stored() {
            // Given fresh isolated suite
            // Then
            #expect(store.load() == nil)
        }
    }

    // MARK: - Helpers

    private func makeCoordinator(downloader: BackgroundDownloadProtocol) -> BackgroundCatalogDownloadCoordinator {
        BackgroundCatalogDownloadCoordinator(
            backgroundDownloader: downloader,
            pendingCatalogFileStore: pendingFileStore,
            backgroundDownloadStateStore: downloadStateStore
        )
    }

    private func makeDownloadedFile(named name: String) throws -> URL {
        // Simulate iOS's ephemeral temp download location — outside Caches/POSPendingCatalog,
        // so the coordinator performs a real move into the staging directory.
        let source = fileManager.temporaryDirectory
            .appendingPathComponent("mock-bg-download-\(UUID().uuidString)-\(name)")
        try Data("{}".utf8).write(to: source)
        return source
    }
}
