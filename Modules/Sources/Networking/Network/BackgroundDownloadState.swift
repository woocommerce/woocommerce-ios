import Foundation

/// Persisted state for background catalog downloads.
/// Allows the app to resume processing downloads after being terminated.
public struct BackgroundDownloadState: Codable {
    let sessionIdentifier: String
    let siteID: Int64

    private static let userDefaultsKey = "com.woocommerce.pos.backgroundDownloadState"
    private static var userDefaults: UserDefaults = .standard

    /// Configure UserDefaults instance for testing.
    /// - Parameter userDefaults: The UserDefaults instance to use for persistence.
    // periphery:ignore - required by tests
    public static func configure(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    /// Saves download state for later retrieval.
    public static func save(_ state: BackgroundDownloadState) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(state) {
            userDefaults.set(encoded, forKey: userDefaultsKey)
        }
    }

    /// Loads saved download state for a specific session identifier.
    public static func load(for sessionIdentifier: String) -> BackgroundDownloadState? {
        guard let data = userDefaults.data(forKey: userDefaultsKey),
              let state = try? JSONDecoder().decode(BackgroundDownloadState.self, from: data),
              state.sessionIdentifier == sessionIdentifier else {
            return nil
        }
        return state
    }

    /// Clears saved download state.
    public static func clear() {
        userDefaults.removeObject(forKey: userDefaultsKey)
    }
}
