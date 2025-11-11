import Foundation

/// Persisted state for background catalog downloads.
/// Allows the app to resume processing downloads after being terminated.
public struct BackgroundDownloadState: Codable {
    let sessionIdentifier: String
    let siteID: Int64
    let startedAt: Date

    private static let userDefaultsKey = "com.woocommerce.pos.backgroundDownloadState"

    /// Saves download state for later retrieval.
    public static func save(_ state: BackgroundDownloadState) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(state) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    /// Loads saved download state for a specific session identifier.
    public static func load(for sessionIdentifier: String) -> BackgroundDownloadState? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let state = try? JSONDecoder().decode(BackgroundDownloadState.self, from: data),
              state.sessionIdentifier == sessionIdentifier else {
            return nil
        }
        return state
    }

    /// Clears saved download state.
    public static func clear() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
