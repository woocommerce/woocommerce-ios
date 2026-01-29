import Foundation

/// Tracks which authentication flow is pending when a magic link is sent.
/// This is used to route the magic link callback to the correct handler when the app
/// is launched from a cold start via the magic link.
enum PendingAuthFlow: String {
    case jetpackSetup
    case notificationSetup
}

struct PendingAuthFlowStorage {
    private let userDefaults: UserDefaults
    private let storageKey = "pendingAuthFlow"

    /// Magic links typically expire in ~10-15 minutes
    private let expirationInterval: TimeInterval = 15 * 60

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var current: PendingAuthFlow? {
        guard let dict = userDefaults.dictionary(forKey: storageKey),
              let flowName = dict.keys.first,
              let timestamp = dict[flowName] as? Date,
              Date().timeIntervalSince(timestamp) < expirationInterval else {
            clear() // Auto-clear if expired or missing data
            return nil
        }
        return PendingAuthFlow(rawValue: flowName)
    }

    func updateCurrentFlow(_ flow: PendingAuthFlow) {
        userDefaults.set([flow.rawValue: Date()], forKey: storageKey)
    }

    func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }
}
