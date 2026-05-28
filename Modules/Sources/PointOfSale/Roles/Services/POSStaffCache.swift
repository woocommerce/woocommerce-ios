import CocoaLumberjackSwift
import Foundation
import struct Networking.POSStaffMember
import KeychainAccess

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

/// `@unchecked Sendable` is sound because `KeychainPOSStaffStorage` serializes via the system
/// Keychain and the test stub is only used under main-actor isolation.
final class POSStaffCache: @unchecked Sendable {
    private let storage: POSStaffKeyValueStorage
    private let now: @Sendable () -> Date
    private(set) var generation: Int = 0

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
        writeStaff(staff, siteID: siteID)
    }

    @discardableResult
    func save(_ staff: [POSStaffMember], siteID: Int64, ifGenerationStill expectedGeneration: Int) -> Bool {
        guard expectedGeneration == generation else { return false }
        writeStaff(staff, siteID: siteID)
        return true
    }

    func clear(siteID: Int64) {
        generation &+= 1
        storage.setString(nil, forKey: staffKey(siteID: siteID))
        storage.setString(nil, forKey: timestampKey(siteID: siteID))
    }

    private func writeStaff(_ staff: [POSStaffMember], siteID: Int64) {
        guard let data = try? JSONEncoder().encode(staff),
              let json = String(data: data, encoding: .utf8) else { return }
        storage.setString(json, forKey: staffKey(siteID: siteID))
        // Hex bit-pattern round-trips losslessly; String(Double) and ISO8601 lose sub-second precision.
        let ref = now().timeIntervalSinceReferenceDate
        storage.setString(String(ref.bitPattern, radix: 16), forKey: timestampKey(siteID: siteID))
    }

    func hasAnyPINs(siteID: Int64) -> Bool {
        load(siteID: siteID)?.contains(where: { $0.pin != nil }) ?? false
    }

    func lastFetched(siteID: Int64) -> Date? {
        // Atomic with the staff payload - a torn cache (timestamp present, payload missing)
        // would otherwise read as "no PINs" and auto-unlock POS without a verified fetch.
        guard load(siteID: siteID) != nil else { return nil }
        guard let raw = storage.string(forKey: timestampKey(siteID: siteID)),
              let bitPattern = UInt64(raw, radix: 16) else { return nil }
        let ref = Double(bitPattern: bitPattern)
        return Date(timeIntervalSinceReferenceDate: ref)
    }

    private func staffKey(siteID: Int64) -> String { "staff.\(siteID)" }
    private func timestampKey(siteID: Int64) -> String { "lastFetched.\(siteID)" }
}

public enum POSStaffCacheCleaner {
    public static func clear(siteID: Int64) {
        POSStaffCache().clear(siteID: siteID)
    }

    public static func clearAll() {
        do {
            try Keychain(service: KeychainPOSStaffStorage.service).removeAll()
        } catch {
            DDLogError("POSStaffCacheCleaner.clearAll failed: \(error)")
        }
    }
}
