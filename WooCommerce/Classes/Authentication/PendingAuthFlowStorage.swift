import Foundation

/// Tracks which authentication flow is pending when a magic link is sent.
/// This is used to route the magic link callback to the correct handler when the app
/// is launched from a cold start via the magic link.
enum PendingAuthFlow: String, Codable {
    case jetpackSetup
}

struct PendingAuthFlowStorage {
    private let userDefaults: UserDefaults
    private let storageKey = UserDefaults.Key.pendingMagicLinkFlow.rawValue

    /// Magic links typically expire in ~10-15 minutes
    private let expirationInterval: TimeInterval = 15 * 60

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var current: PendingAuthFlow? {
        guard let object = userDefaults.data(forKey: storageKey),
              let storedFlow = try? JSONDecoder().decode(StoredFlow.self, from: object),
              Date().timeIntervalSince(storedFlow.timestamp) < expirationInterval else {
            clear() // Auto-clear if expired or missing data
            return nil
        }
        return storedFlow.flow
    }

    func updateCurrentFlow(_ flow: PendingAuthFlow) {
        let stored = StoredFlow(flow: flow, timestamp: Date())
        userDefaults.set(try? JSONEncoder().encode(stored), forKey: storageKey)
    }

    func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }
}

extension PendingAuthFlowStorage {
    struct StoredFlow: Codable {
        let flow: PendingAuthFlow
        let timestamp: Date
    }
}
