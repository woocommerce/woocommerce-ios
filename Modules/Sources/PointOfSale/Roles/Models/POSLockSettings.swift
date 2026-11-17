import CocoaLumberjackSwift
import Foundation
import Observation

enum POSInactivityLockTimeout: Int, CaseIterable, Codable, Sendable {
    case never = 0
    case oneMinute = 1
    case twoMinutes = 2
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15

    /// `nil` turns inactivity locking off.
    var interval: TimeInterval? {
        self == .never ? nil : TimeInterval(rawValue * 60)
    }
}

// New fields need a decoder migration that preserves existing saved choices.
struct POSLockPreferences: Codable, Equatable, Sendable {
    var locksWhenPOSOpens = true
    var locksInBackground = true
    var locksAfterSale = false
    var inactivityTimeout: POSInactivityLockTimeout = .fiveMinutes
}

/// The Security "Lock POS when" preferences for one store on this device.
@MainActor
@Observable
final class POSLockSettings {
    private(set) var preferences: POSLockPreferences

    @ObservationIgnored private let key: String
    @ObservationIgnored private let userDefaults: UserDefaults

    init(siteID: Int64, userDefaults: UserDefaults = .standard) {
        self.key = Self.key(for: siteID)
        self.userDefaults = userDefaults
        self.preferences = Self.load(key: key, from: userDefaults)
    }

    func update(_ change: (inout POSLockPreferences) -> Void) {
        var updated = preferences
        change(&updated)
        guard updated != preferences else { return }
        preferences = updated
        do {
            userDefaults.set(try JSONEncoder().encode(updated), forKey: key)
        } catch {
            DDLogError("POS lock settings could not be saved (error: \(error))")
        }
    }

    /// Logout clears the local PIN setup, so the lock preferences that belong to it go too.
    nonisolated static func clearAll(in userDefaults: UserDefaults) {
        let prefix = "\(baseKey)."
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            userDefaults.removeObject(forKey: key)
        }
    }
}

private extension POSLockSettings {
    nonisolated static let baseKey = "com.woocommerce.pos.lockSettings"

    static func key(for siteID: Int64) -> String {
        "\(baseKey).\(siteID)"
    }

    static func load(key: String, from userDefaults: UserDefaults) -> POSLockPreferences {
        guard let data = userDefaults.data(forKey: key) else { return POSLockPreferences() }
        do {
            return try JSONDecoder().decode(POSLockPreferences.self, from: data)
        } catch {
            DDLogError("POS lock settings could not be read; using defaults (error: \(error))")
            return POSLockPreferences()
        }
    }
}
