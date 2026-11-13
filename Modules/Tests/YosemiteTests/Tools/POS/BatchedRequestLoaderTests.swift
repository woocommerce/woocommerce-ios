import Foundation
import Testing
import Alamofire
@testable import Networking
@testable import Yosemite

struct BatchedRequestLoaderTests {

    // MARK: - Basic Functionality Tests

    @Test func loadAll_loads_single_page_successfully() async throws {
        // Given
        let sut = BatchedRequestLoader(batchSize: 2)
        let expectedItems = ["item1", "item2", "item3"]
        let callCount = Counter()

        let makeRequest: (Int) async throws -> PagedItems<String> = { pageNumber in
            await callCount.increment()
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
        #expect(result.items == expectedItems)
        #expect(await callCount.value == 2) // batchSize = 2, so it fetches pages 1 and 2
    }

    @Test func loadAll_returns_earliest_server_date_across_pages() async throws {
        // Given
        let sut = BatchedRequestLoader(batchSize: 3)
        let earlier = Date(timeIntervalSince1970: 1_000)
        let later = Date(timeIntervalSince1970: 2_000)

        let makeRequest: (Int) async throws -> PagedItems<String> = { pageNumber in
            // Page 2 carries the earliest server date; the loader should surface that one.
            let serverDate = pageNumber == 2 ? earlier : later
            return PagedItems(items: ["page \(pageNumber)"],
                              hasMorePages: pageNumber < 3,
                              totalItems: 3,
                              serverDate: serverDate)
        }

        // When
        let result = try await sut.loadAll(makeRequest: makeRequest)

        // Then
        #expect(result.serverDate == earlier)
    }

    @Test func loadAll_returns_nil_server_date_when_no_page_provides_one() async throws {
        // Given
        let sut = BatchedRequestLoader(batchSize: 2)
        let makeRequest: (Int) async throws -> PagedItems<String> = { pageNumber in
            PagedItems(items: pageNumber == 1 ? ["a"] : [], hasMorePages: false, totalItems: 1)
        }

        // When
        let result = try await sut.loadAll(makeRequest: makeRequest)

        // Then
        #expect(result.serverDate == nil)
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

        let attemptCountForPage1 = Counter()
        let attemptCountForPage2 = Counter()
        let attemptCountForPage3 = Counter()
        let makeRequest: (Int) async throws -> PagedItems<String> = { pageNumber in
            switch pageNumber {
            case 1:
                await attemptCountForPage1.increment()
            case 2:
                await attemptCountForPage2.increment()
                // Page 2 fails once, then succeeds
                if await attemptCountForPage2.value == 1 {
                    throw URLError(.timedOut)
                }
            case 3:
                await attemptCountForPage3.increment()
            default:
                throw NSError(domain: "Invalid page number", code: 0)
            }

            return PagedItems(items: ["page \(pageNumber) success"], hasMorePages: false, totalItems: 1)
        }

        // When
        let result = try await sut.loadAll(makeRequest: makeRequest)

        // Then
        #expect(result.items == ["page 1 success", "page 2 success", "page 3 success"])
        #expect(await attemptCountForPage1.value == 1) // Page 1 succeeded immediately
        #expect(await attemptCountForPage2.value == 2) // Page 2 failed once, then succeeded
        #expect(await attemptCountForPage3.value == 1) // Page 3 succeeded immediately
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

        let attemptCount = Counter()
        let makeRequest: (Int) async throws -> PagedItems<String> = { _ in
            await attemptCount.increment()
            throw NetworkError.unacceptableStatusCode(statusCode: 401, response: nil)
        }

        // When/Then
        await #expect(throws: NetworkError.self) {
            try await sut.loadAll(makeRequest: makeRequest)
        }
        #expect(await attemptCount.value == 2) // No retries for non-retryable error for both pages
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

        let attemptCount = Counter()
        let expectedError = URLError(.networkConnectionLost)
        let makeRequest: (Int) async throws -> PagedItems<String> = { _ in
            await attemptCount.increment()
            throw expectedError
        }

        // When/Then
        await #expect(throws: URLError.self) {
            try await sut.loadAll(makeRequest: makeRequest)
        }
        #expect(await attemptCount.value == 3) // maxRetries = 3
    }

    // MARK: - DefaultRetryErrorEvaluator Tests

    @Test func defaultRetryErrorEvaluator_does_not_retry_cancellation_error() {
        // Given
        let sut = DefaultRetryErrorEvaluator()
        let error = CancellationError()

        // When
        let shouldRetry = sut.shouldRetry(error)

        // Then
        #expect(!shouldRetry)
    }

    @Test func defaultRetryErrorEvaluator_does_not_retry_alamofire_explicitly_cancelled() {
        // Given
        let sut = DefaultRetryErrorEvaluator()
        let error = AFError.explicitlyCancelled

        // When
        let shouldRetry = sut.shouldRetry(error)

        // Then
        #expect(!shouldRetry)
    }

    @Test func defaultRetryErrorEvaluator_does_not_retry_invalid_cookie_nonce() {
        // Given
        let sut = DefaultRetryErrorEvaluator()
        let error = NetworkError.invalidCookieNonce

        // When
        let shouldRetry = sut.shouldRetry(error)

        // Then
        #expect(!shouldRetry)
    }

    @Test func defaultRetryErrorEvaluator_retries_network_errors() {
        // Given
        let sut = DefaultRetryErrorEvaluator()
        let error = NetworkError.timeout()

        // When
        let shouldRetry = sut.shouldRetry(error)

        // Then
        #expect(shouldRetry)
    }

    @Test func defaultRetryErrorEvaluator_retries_url_errors() {
        // Given
        let sut = DefaultRetryErrorEvaluator()
        let error = URLError(.networkConnectionLost)

        // When
        let shouldRetry = sut.shouldRetry(error)

        // Then
        #expect(shouldRetry)
    }
}

// MARK: - Mock Error Evaluator

private struct MockRetryErrorEvaluator: RetryErrorEvaluator {
    let shouldRetry: Bool

    func shouldRetry(_ error: Error) -> Bool {
        shouldRetry
    }
}
