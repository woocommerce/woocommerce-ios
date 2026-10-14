import Foundation
import os

/// Protocol for accessing the discovered WordPress REST API root URL for a given site.
///
public protocol RESTAPIRootCaching {
    func root(for siteURL: String) -> String?
    func removeRoot(_ root: String, for siteURL: String)
}

/// Thread-safe in-memory cache for discovered WordPress REST API root URLs.
/// Not persisted — fresh per app session.
///
public final class WordPressRESTAPIRootCache: RESTAPIRootCaching, Sendable {
    public static let shared = WordPressRESTAPIRootCache()

    private let cache = OSAllocatedUnfairLock<[String: String]>(initialState: [:])

    init() {}

    public func root(for siteURL: String) -> String? {
        cache.withLock { $0[siteURL.trimSlashes().lowercased()] }
    }

    public func setRoot(_ root: String, for siteURL: String) {
        cache.withLock { $0[siteURL.trimSlashes().lowercased()] = root }
    }

    public func removeRoot(_ root: String, for siteURL: String) {
        cache.withLock { cache in
            let key = siteURL.trimSlashes().lowercased()
            guard cache[key] == root else { return }
            cache[key] = nil
        }
    }

    public func reset() {
        cache.withLock { $0.removeAll() }
    }
}
