import Foundation

/// Thread-safe in-memory cache for discovered WordPress REST API root URLs.
/// Not persisted — fresh per app session.
///
public final class WordPressRESTAPIRootCache: RESTAPIRootCaching {
    public static let shared = WordPressRESTAPIRootCache()

    private var cache: [String: String] = [:]
    private let queue = DispatchQueue(label: "WordPressRESTAPIRootCache", attributes: .concurrent)

    private init() {}

    public func root(for siteURL: String) -> String? {
        queue.sync { cache[siteURL.trimSlashes()] }
    }

    public func setRoot(_ root: String, for siteURL: String) {
        queue.async(flags: .barrier) { self.cache[siteURL.trimSlashes()] = root }
    }

    public func reset() {
        queue.async(flags: .barrier) { self.cache.removeAll() }
    }
}
