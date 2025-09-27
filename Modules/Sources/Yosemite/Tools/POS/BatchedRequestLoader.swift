import Foundation

/// Generic utility for loading paginated data with batch processing.
final class BatchedRequestLoader {
    private let batchSize: Int

    init(batchSize: Int) {
        self.batchSize = batchSize
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
                    group.addTask {
                        let result = try await makeRequest(pageNumber)
                        return PageResult(pageNumber: pageNumber, items: result)
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
}

private struct PageResult<T> {
    let pageNumber: Int
    let items: PagedItems<T>
}
