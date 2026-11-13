import Foundation
import Testing
@testable import Networking

struct MockPOSCatalogSyncRemoteTests {
    @Test func test_requestCatalogGeneration_when_called_concurrently_then_consumes_each_result_once() async throws {
        // Given
        let remote = MockPOSCatalogSyncRemote()
        let requestCount = 1_000
        let expectedURLs = (0..<requestCount).map { "https://example.com/catalog-\($0).json" }
        remote.catalogRequestSequence = expectedURLs.map { .success(.init(status: .completed, downloadURL: $0)) }

        // When
        let urls = try await withThrowingTaskGroup(of: String?.self) { group in
            for _ in 0..<requestCount {
                group.addTask {
                    try await remote.requestCatalogGeneration(for: 123, forceGeneration: true, allowCellular: false).downloadURL
                }
            }
            var urls: [String] = []
            for try await url in group {
                if let url {
                    urls.append(url)
                }
            }
            return urls
        }

        // Then
        #expect(urls.count == requestCount)
        #expect(Set(urls) == Set(expectedURLs))
        #expect(remote.catalogRequestCallCount == requestCount)
        #expect(remote.lastCatalogRequestForceGeneration == true)
        #expect(remote.lastCatalogDownloadAllowCellular == false)
    }

    @Test func test_parseDownloadedCatalog_when_called_concurrently_then_records_every_call() async throws {
        // Given
        let remote = MockPOSCatalogSyncRemote()
        let requestCount = 1_000
        let fileURL = URL(fileURLWithPath: "/tmp/catalog.json")

        // When
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<requestCount {
                group.addTask {
                    _ = try await remote.parseDownloadedCatalog(from: fileURL, siteID: 123)
                }
            }
            try await group.waitForAll()
        }

        // Then
        #expect(remote.parseDownloadedCatalogCallCount == requestCount)
        #expect(remote.lastParsedFileURL == fileURL)
        #expect(remote.lastParsedSiteID == 123)
    }
}
