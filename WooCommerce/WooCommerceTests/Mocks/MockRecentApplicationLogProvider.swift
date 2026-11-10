import Foundation
@testable import WooCommerce

struct MockRecentApplicationLogProvider: RecentApplicationLogProviding {
    var logEntries: [RecentApplicationLogEntry] = []

    func entries(since: Date, limit: Int) -> [RecentApplicationLogEntry] {
        Array(logEntries.filter { $0.date >= since }.suffix(max(0, limit)))
    }
}
