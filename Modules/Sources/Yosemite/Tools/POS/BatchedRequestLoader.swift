import Foundation
import Networking
import Alamofire

/// Protocol for determining which errors should be retried.
protocol RetryErrorEvaluator {
    func shouldRetry(_ error: Error) -> Bool
}

/// Default implementation that retries network errors and server errors.
struct DefaultRetryErrorEvaluator: RetryErrorEvaluator {
    func shouldRetry(_ error: Error) -> Bool {
        // Don't retry cancellation errors
        if error is CancellationError {
            return false
        }

        if let afError = error as? AFError, case .explicitlyCancelled = afError {
            return false
        }

        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidCookieNonce:
                // Don't retry on auth errors that require user action to log in again.
                return false
            default:
                return true
            }
        }
        return true
    }
}

/// Generic utility for loading paginated data with batch processing and retry support.
final class BatchedRequestLoader {
    private let batchSize: Int
    private let maxRetries: Int
    private let retryDelay: TimeInterval
    private let errorEvaluator: RetryErrorEvaluator

    init(batchSize: Int,
         maxRetries: Int = 4,
         retryDelay: TimeInterval = 2.0,
         errorEvaluator: RetryErrorEvaluator = DefaultRetryErrorEvaluator()) {
        self.batchSize = batchSize
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.errorEvaluator = errorEvaluator
    }

    /// Loads all items using a paginated request function.
    /// - Parameters:
    ///   - makeRequest: Function that takes a page number and returns PagedItems<T>.
    /// - Returns: Array of all loaded items.
    func loadAll<T>(makeRequest: @escaping (Int) async throws -> PagedItems<T>) async throws -> [T] {
        var allItems: [T] = []
        var currentPage = 1
        var hasMorePages = true

        while hasMorePages {
            let pagesToFetch = Array(currentPage..<(currentPage + batchSize))

            let batchResults = try await withThrowingTaskGroup(of: PageResult<T>.self) { group in
                for pageNumber in pagesToFetch {
                    group.addTask { [maxRetries, retryDelay, errorEvaluator] in
                        let pagedItems = try await Self.fetchPageWithRetry(
                            pageNumber: pageNumber,
                            maxRetries: maxRetries,
                            retryDelay: retryDelay,
                            errorEvaluator: errorEvaluator,
                            makeRequest: makeRequest
                        )
                        return PageResult(pageNumber: pageNumber, items: pagedItems)
                    }
                }

                var results: [PageResult<T>] = []
                for try await result in group {
                    results.append(result)
                }
                return results.sorted(by: { $0.pageNumber < $1.pageNumber })
            }

            // Processes results in order and checks if there are more pages.
            let newItems = batchResults.flatMap { $0.items.items }
            allItems.append(contentsOf: newItems)

            let highestPageResult = batchResults.last?.items
            hasMorePages = (highestPageResult?.hasMorePages ?? false) && !newItems.isEmpty
            currentPage += batchSize
        }

        return allItems
    }

    private static func fetchPageWithRetry<T>(
        pageNumber: Int,
        maxRetries: Int,
        retryDelay: TimeInterval,
        errorEvaluator: RetryErrorEvaluator,
        makeRequest: @escaping (Int) async throws -> PagedItems<T>
    ) async throws -> PagedItems<T> {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                return try await makeRequest(pageNumber)
            } catch {
                lastError = error

                if !errorEvaluator.shouldRetry(error) {
                    DDLogError("⛔️ Page \(pageNumber) failed with non-retryable error: \(error)")
                    throw error
                }

                // Logs and retries with exponential backoff.
                if attempt < maxRetries - 1 {
                    let delay = retryDelay * pow(2.0, Double(attempt))
                    DDLogWarn("⚠️ Page \(pageNumber) failed (attempt \(attempt + 1)/\(maxRetries)): \(error). Retrying in \(delay)s...")
                    try await Task.sleep(nanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
                } else {
                    DDLogError("⛔️ Page \(pageNumber) failed after \(maxRetries) attempts: \(error)")
                }
            }
        }

        throw lastError ?? URLError(.unknown)
    }
}

private struct PageResult<T> {
    let pageNumber: Int
    let items: PagedItems<T>
}
