import CocoaLumberjackSwift
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
    static let service = "com.woocommerce.pos.staffCache"

    private let keychain: Keychain

    init(service: String = KeychainPOSStaffStorage.service) {
        self.keychain = Keychain(service: service)
    }

    // Returns nil for both "absent" and "locked"; callers tolerate stale-cache. Reads
    // surface as nil but are logged so a Keychain permission issue isn't silent.
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

/// Per-site cache of the `/staff` response, encoded as JSON in Keychain. Reads/writes flow
/// through the injected `POSStaffKeyValueStorage`. `@unchecked Sendable` is sound because the
/// default `KeychainPOSStaffStorage` serializes via the system Keychain, and the test stub is
/// used only under main-actor isolation.
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

    /// Save guarded by a generation token captured before the fetch. If `clear` ran while the
    /// fetch was in flight, the captured generation no longer matches and the save is dropped
    /// - otherwise a logout/site-switch mid-fetch would repopulate the cache with stale PINs.
    func save(_ staff: [POSStaffMember], siteID: Int64, ifGenerationStill expectedGeneration: Int) {
        guard expectedGeneration == generation else { return }
        writeStaff(staff, siteID: siteID)
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
        // Hex bit-pattern of TimeIntervalSinceReferenceDate round-trips losslessly; String(Double)
        // and ISO8601 alternatives lose sub-second precision.
        let ref = now().timeIntervalSinceReferenceDate
        storage.setString(String(ref.bitPattern, radix: 16), forKey: timestampKey(siteID: siteID))
    }

    func hasAnyPINs(siteID: Int64) -> Bool {
        load(siteID: siteID)?.contains(where: { $0.pin != nil }) ?? false
    }

    func lastFetched(siteID: Int64) -> Date? {
        // Atomic with the staff payload: a timestamp without a readable staff list means
        // the cache is incomplete and must be treated as cold, otherwise a missing/corrupt
        // staff key reads as "no PINs" and unlocks POS without a verified /staff result.
        guard load(siteID: siteID) != nil else { return nil }
        guard let raw = storage.string(forKey: timestampKey(siteID: siteID)),
              let bitPattern = UInt64(raw, radix: 16) else { return nil }
        let ref = Double(bitPattern: bitPattern)
        return Date(timeIntervalSinceReferenceDate: ref)
    }

    private func staffKey(siteID: Int64) -> String { "staff.\(siteID)" }
    private func timestampKey(siteID: Int64) -> String { "lastFetched.\(siteID)" }
}

/// Public entry point for wiping the per-site staff PIN cache from outside the PointOfSale
/// module. Used by the app target on logout / site-switch lifecycle events so a previous
/// tenant's cached PIN hashes can't survive into a new user session. Uses the default
/// Keychain-backed storage; safe to call when POS is not mounted.
public enum POSStaffCacheCleaner {
    public static func clear(siteID: Int64) {
        POSStaffCache().clear(siteID: siteID)
    }

    /// Wipes the staff cache for every site this app has ever cached. Use on logout so a
    /// previous account's cached PIN hashes can't survive into a new user session - per-site
    /// `clear` only handles the currently-mounted site and would leave entries from other
    /// sites the user has ever opened POS for.
    public static func clearAll() {
        do {
            try Keychain(service: KeychainPOSStaffStorage.service).removeAll()
        } catch {
            DDLogError("POSStaffCacheCleaner.clearAll failed: \(error)")
        }
    }
}
