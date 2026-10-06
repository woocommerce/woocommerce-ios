import Foundation
import Testing
@testable import WooCommerce

struct MockURLSessionTests {
    @Test
    func test_data_when_requested_concurrently_then_records_every_request_and_returns_stubbed_response() async throws {
        // Given
        let session = MockURLSession()
        let url = try #require(URL(string: "https://example.com"))
        let expectedData = Data("response".utf8)
        session.simulateResponse(for: url.absoluteString, data: expectedData)
        let requestCount = 100

        // When
        let responses = try await withThrowingTaskGroup(of: Data.self) { group in
            for _ in 0..<requestCount {
                group.addTask {
                    let (data, _) = try await session.data(for: URLRequest(url: url))
                    return data
                }
            }
            var responses: [Data] = []
            for try await response in group {
                responses.append(response)
            }
            return responses
        }

        // Then
        #expect(responses.count == requestCount)
        #expect(responses.allSatisfy { $0 == expectedData })
        #expect(session.requestCount == requestCount)
        #expect(session.receivedRequests.count == requestCount)
        #expect(session.receivedRequests.allSatisfy { $0.url == url })
        #expect(session.lastRequest?.url == url)
    }
}
