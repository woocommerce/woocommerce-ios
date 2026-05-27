import Foundation
import struct Networking.POSStaffMember
import KeychainAccess

/// Backing storage for `POSStaffCache`. Protocol exists so tests can inject an in-memory stub
/// without touching the real Keychain.
///
protocol POSStaffKeyValueStorage: Sendable {
    func string(forKey key: String) -> String?
    func setString(_ value: String?, forKey key: String)
}

/// `Keychain`-backed `POSStaffKeyValueStorage`.
///
struct KeychainPOSStaffStorage: POSStaffKeyValueStorage {
    private let keychain: Keychain

    init(service: String = "com.woocommerce.pos.staffCache") {
        self.keychain = Keychain(service: service)
    }

    func string(forKey key: String) -> String? {
        try? keychain.get(key)
    }

    func setString(_ value: String?, forKey key: String) {
        if let value {
            try? keychain.set(value, key: key)
        } else {
            try? keychain.remove(key)
        }
    }
}

/// In-memory `POSStaffKeyValueStorage` for tests.
///
final class InMemoryKeyValueStorage: POSStaffKeyValueStorage, @unchecked Sendable {
    private var store: [String: String] = [:]

    func string(forKey key: String) -> String? { store[key] }
    func setString(_ value: String?, forKey key: String) {
        if let value { store[key] = value } else { store.removeValue(forKey: key) }
    }
}

/// Per-site cache of the `/staff` response, encoded as JSON in Keychain. Tracks `lastFetched`
/// so `DefaultPOSAccessSession.refreshPINStatus()` can apply a 30s soft TTL.
///
final class POSStaffCache: @unchecked Sendable {
    private let storage: POSStaffKeyValueStorage
    private let now: @Sendable () -> Date

    init(storage: POSStaffKeyValueStorage = KeychainPOSStaffStorage(),
         now: @escaping @Sendable () -> Date = Date.init) {
        self.storage = storage
        self.now = now
    }

    func load(siteID: Int64) -> [POSStaffMember]? {
        guard let json = storage.string(forKey: staffKey(siteID: siteID)),
              let data = json.data(using: .utf8),
              let members = try? JSONDecoder().decode([POSStaffMember].self, from: data) else {
            return nil
        }
        return members
    }

    func save(_ staff: [POSStaffMember], siteID: Int64) {
        guard let data = try? JSONEncoder().encode(staff),
              let json = String(data: data, encoding: .utf8) else { return }
        storage.setString(json, forKey: staffKey(siteID: siteID))
        let ref = now().timeIntervalSinceReferenceDate
        storage.setString(String(ref.bitPattern, radix: 16), forKey: timestampKey(siteID: siteID))
    }

    func clear(siteID: Int64) {
        storage.setString(nil, forKey: staffKey(siteID: siteID))
        storage.setString(nil, forKey: timestampKey(siteID: siteID))
    }

    func hasAnyPINs(siteID: Int64) -> Bool {
        load(siteID: siteID)?.contains(where: { $0.pin != nil }) ?? false
    }

    func lastFetched(siteID: Int64) -> Date? {
        guard let raw = storage.string(forKey: timestampKey(siteID: siteID)),
              let bitPattern = UInt64(raw, radix: 16) else { return nil }
        let ref = Double(bitPattern: bitPattern)
        return Date(timeIntervalSinceReferenceDate: ref)
    }

    private func staffKey(siteID: Int64) -> String { "staff.\(siteID)" }
    private func timestampKey(siteID: Int64) -> String { "lastFetched.\(siteID)" }
}
