import Foundation
import Testing
@testable import Networking
@testable import Yosemite

struct BatchedRequestLoaderTests {

    // MARK: - Basic Functionality Tests

    @Test func loadAll_loads_single_page_successfully() async throws {
        // Given
        let sut = BatchedRequestLoader(batchSize: 2)
        let expectedItems = ["item1", "item2", "item3"]
        var callCount = 0

        let makeRequest: (Int) async throws -> PagedItems<String> = { pageNumber in
            callCount += 1
            #expect(pageNumber == 1 || pageNumber == 2)
            if pageNumber == 1 {
                return PagedItems(items: expectedItems, hasMorePages: false, totalItems: 3)
            } else {
                return PagedItems(items: [], hasMorePages: false, totalItems: 0)
            }
        }

        // When
        let result = try await sut.loadAll(makeRequest: makeRequest)

        // Then
        #expect(result == expectedItems)
        #expect(callCount == 2) // batchSize = 2, so it fetches pages 1 and 2
    }

    // MARK: - Retry Logic Tests

    @Test func loadAll_retries_individual_pages_independently() async throws {
        // Given
        let mockErrorEvaluator = MockRetryErrorEvaluator(shouldRetry: true)
        let sut = BatchedRequestLoader(
            batchSize: 3,
            maxRetries: 3,
            retryDelay: 0.01,
            errorEvaluator: mockErrorEvaluator
        )

        var attemptsByPage: [Int: Int] = [:]
        let makeRequest: (Int) async throws -> PagedItems<String> = { pageNumber in
            attemptsByPage[pageNumber, default: 0] += 1

            // Page 2 fails once, then succeeds
            if pageNumber == 2 && attemptsByPage[pageNumber] == 1 {
                throw URLError(.timedOut)
            }

            return PagedItems(items: ["page \(pageNumber) success"], hasMorePages: false, totalItems: 1)
        }

        // When
        let result = try await sut.loadAll(makeRequest: makeRequest)

        // Then
        #expect(result == ["page 1 success", "page 2 success", "page 3 success"])
        #expect(attemptsByPage[1] == 1) // Page 1 succeeded immediately
        #expect(attemptsByPage[2] == 2) // Page 2 failed once, then succeeded
        #expect(attemptsByPage[3] == 1) // Page 3 succeeded immediately
    }

    @Test func loadAll_does_not_retry_on_non_retryable_error() async throws {
        // Given
        let mockErrorEvaluator = MockRetryErrorEvaluator(shouldRetry: false)
        let sut = BatchedRequestLoader(
            batchSize: 2,
            maxRetries: 3,
            retryDelay: 0.01,
            errorEvaluator: mockErrorEvaluator
        )

        var attemptCount = 0
        let makeRequest: (Int) async throws -> PagedItems<String> = { pageNumber in
            attemptCount += 1
            throw NetworkError.unacceptableStatusCode(statusCode: 401, response: nil)
        }

        // When/Then
        await #expect(throws: NetworkError.self) {
            try await sut.loadAll(makeRequest: makeRequest)
        }
        #expect(attemptCount == 2) // No retries for non-retryable error for both pages
    }

    @Test func loadAll_fails_after_max_retries() async throws {
        // Given
        let mockErrorEvaluator = MockRetryErrorEvaluator(shouldRetry: true)
        let sut = BatchedRequestLoader(
            batchSize: 1,
            maxRetries: 3,
            retryDelay: 0.01,
            errorEvaluator: mockErrorEvaluator
        )

        var attemptCount = 0
        let expectedError = URLError(.networkConnectionLost)
        let makeRequest: (Int) async throws -> PagedItems<String> = { pageNumber in
            attemptCount += 1
            throw expectedError
        }

        // When/Then
        await #expect(throws: URLError.self) {
            try await sut.loadAll(makeRequest: makeRequest)
        }
        #expect(attemptCount == 3) // maxRetries = 3
    }
}

// MARK: - Mock Error Evaluator

private struct MockRetryErrorEvaluator: RetryErrorEvaluator {
    let shouldRetry: Bool

    func shouldRetry(_ error: Error) -> Bool {
        shouldRetry
    }
}
