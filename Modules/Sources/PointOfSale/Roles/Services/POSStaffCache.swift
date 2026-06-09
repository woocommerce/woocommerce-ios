import CocoaLumberjackSwift
import Foundation
import struct Networking.POSStaffMember
@preconcurrency import KeychainAccess

protocol POSStaffKeyValueStorage: Sendable {
    func string(forKey key: String) -> String?
    func setString(_ value: String?, forKey key: String)
}

struct KeychainPOSStaffStorage: POSStaffKeyValueStorage {
    static let service = "com.woocommerce.pos.staffCache"

    private let keychain: Keychain

    init(service: String = KeychainPOSStaffStorage.service) {
        self.keychain = Keychain(service: service)
    }

    func string(forKey key: String) -> String? {
        do {
            return try keychain.get(key)
        } catch {
            DDLogError("POSStaffCache keychain read failed for key=\(key): \(error)")
            return nil
        }
    }

    func setString(_ value: String?, forKey key: String) {
        do {
            if let value {
                try keychain.set(value, key: key)
            } else {
                try keychain.remove(key)
            }
        } catch {
            DDLogError("POSStaffCache keychain write failed for key=\(key): \(error)")
        }
    }
}

final class POSStaffCache: Sendable {
    private let storage: POSStaffKeyValueStorage
    private let now: @Sendable () -> Date

    init(storage: POSStaffKeyValueStorage = KeychainPOSStaffStorage(),
         now: @escaping @Sendable () -> Date = { Date() }) {
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
        storage.setString(String(now().timeIntervalSince1970), forKey: timestampKey(siteID: siteID))
    }

    func clear(siteID: Int64) {
        storage.setString(nil, forKey: staffKey(siteID: siteID))
        storage.setString(nil, forKey: timestampKey(siteID: siteID))
    }

    func lastFetched(siteID: Int64) -> Date? {
        // Read atomically with the staff payload - a torn cache (timestamp present, payload missing)
        // would otherwise read as "no PINs" and auto-unlock POS without a verified fetch.
        guard load(siteID: siteID) != nil else { return nil }
        guard let raw = storage.string(forKey: timestampKey(siteID: siteID)),
              let interval = TimeInterval(raw) else { return nil }
        return Date(timeIntervalSince1970: interval)
    }
}

// MARK: - Derived queries

extension POSStaffCache {
    /// `true` when the cached staff list for the site contains at least one member with a PIN.
    func hasAnyPINs(siteID: Int64) -> Bool {
        load(siteID: siteID)?.contains(where: { $0.pin != nil }) ?? false
    }
}

// MARK: - Storage keys

private extension POSStaffCache {
    func staffKey(siteID: Int64) -> String { "staff.\(siteID)" }
    func timestampKey(siteID: Int64) -> String { "lastFetched.\(siteID)" }
}
