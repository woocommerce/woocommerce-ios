import Foundation

/// Persisted state for background catalog downloads.
/// Allows the app to resume processing downloads after being terminated.
public struct BackgroundDownloadState: Codable {
    let sessionIdentifier: String
    let siteID: Int64
}

/// Persists `BackgroundDownloadState` to `UserDefaults`.
///
/// `key` is the seam for site-scoped storage: callers can pass a site-suffixed key
/// (e.g. `"com.woocommerce.pos.backgroundDownloadState.\(siteID)"`)
public struct BackgroundDownloadStateStore {
    private let userDefaults: UserDefaults
    private let key: String

    public init(userDefaults: UserDefaults = .standard,
                key: String = "com.woocommerce.pos.backgroundDownloadState") {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func save(_ state: BackgroundDownloadState) {
        if let encoded = try? JSONEncoder().encode(state) {
            userDefaults.set(encoded, forKey: key)
        }
    }

    /// Loads saved download state, returning it only if its session identifier matches.
    public func load(for sessionIdentifier: String) -> BackgroundDownloadState? {
        guard let data = userDefaults.data(forKey: key),
              let state = try? JSONDecoder().decode(BackgroundDownloadState.self, from: data),
              state.sessionIdentifier == sessionIdentifier else {
            return nil
        }
        return state
    }

    public func clear() {
        userDefaults.removeObject(forKey: key)
    }
}
