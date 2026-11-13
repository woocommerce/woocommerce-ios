import Foundation
import Networking
import Testing

@Suite(.timeLimit(.minutes(5)))
struct MockBackgroundDownloaderTests {
    @Test func test_calls_when_concurrent_then_records_every_operation() async throws {
        // Given
        let downloader = MockBackgroundDownloader()
        let fileURL = URL(fileURLWithPath: "/tmp/catalog.json")
        downloader.mockSuccessfulDownload(fileURL: fileURL)
        downloader.mockFileURL = fileURL
        let count = 1_000

        // When
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<count {
                group.addTask {
                    let result = try await downloader.downloadFile(from: fileURL, sessionIdentifier: "download-\(index)", allowCellular: true)
                    #expect(result.fileURL == fileURL)
                    let reconnectedURL = await downloader.reconnectToSession(identifier: "reconnect-\(index)", allowCellular: true) {}
                    #expect(reconnectedURL == fileURL)
                    await downloader.cancelDownloads(for: "cancel-\(index)")
                }
            }
            try await group.waitForAll()
        }

        // Then
        #expect(downloader.downloadCallCount == count)
        #expect(downloader.reconnectSessionCallCount == count)
        #expect(downloader.cancelCallCount == count)
    }

    @Test func test_callbacks_when_accessing_mock_then_run_outside_lock() async throws {
        // Given
        let downloader = MockBackgroundDownloader()
        let fileURL = URL(fileURLWithPath: "/tmp/catalog.json")
        downloader.onDownloadStarted = {
            #expect(downloader.downloadCallCount == 1)
            #expect(downloader.lastSessionIdentifier == "catalog")
            downloader.mockSuccessfulDownload(fileURL: fileURL)
            downloader.onDownloadStarted = nil
        }
        downloader.setBackgroundCompletionHandler {
            downloader.reset()
        }

        // When
        let result = try await downloader.downloadFile(from: fileURL, sessionIdentifier: "catalog", allowCellular: true)
        downloader.simulateBackgroundCompletion()

        // Then
        #expect(result.fileURL == fileURL)
        #expect(downloader.downloadCallCount == 0)
        #expect(downloader.lastSessionIdentifier == nil)
        #expect(downloader.backgroundCompletionHandler == nil)
    }
}
