import Foundation

enum BoundedTaskGroup {

    /// Runs `body` over `items` with at most `limit` concurrent tasks; results
    /// are returned in the same order as `items`. Throws nothing on its own.
    static func runOrdered<Item: Sendable, Result: Sendable>(
        _ items: [Item],
        limit: Int,
        body: @escaping @Sendable (Item) async -> Result
    ) async -> [Result] {
        guard !items.isEmpty else { return [] }
        let clampedLimit = max(1, limit)
        var collected: [(Int, Result)] = []
        await withTaskGroup(of: (Int, Result).self) { group in
            var nextIndex = 0
            var inFlight = 0
            while nextIndex < items.count {
                while inFlight < clampedLimit, nextIndex < items.count {
                    let index = nextIndex
                    let item = items[index]
                    group.addTask { (index, await body(item)) }
                    nextIndex += 1
                    inFlight += 1
                }
                if let next = await group.next() {
                    collected.append(next)
                    inFlight -= 1
                }
            }
            for await pair in group {
                collected.append(pair)
            }
        }
        return collected.sorted { $0.0 < $1.0 }.map { $0.1 }
    }
}
