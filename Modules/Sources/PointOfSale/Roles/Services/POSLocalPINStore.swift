import CocoaLumberjackSwift
import Foundation
import KeychainAccess

enum POSPINStoreError: Error, Equatable {
    case invalidPINFormat
    case adminPINRequired
    case pinMatchesOtherRole
    case storageFailure
}

/// Stores the local Admin and optional Cashier PIN of one store, on this device only.
final class POSLocalPINStore: POSPINCredentialProviding, POSPINManaging {
    private let siteID: Int64
    private let storage: POSSecureStorage
    private let iterations: Int
    private let logoutEpoch: UUID

    init(siteID: Int64,
         storage: POSSecureStorage = KeychainPOSSecureStorage(),
         iterations: Int = POSPINHash.Constants.defaultIterations) {
        self.siteID = siteID
        self.storage = storage
        self.iterations = iterations
        self.logoutEpoch = POSPINAttemptContext.logoutEpoch(scopeID: storage.scopeID)
    }

    func credentials() throws(POSPINStoreError) -> [POSPINCredential] {
        let pins = try loadPINs()
        // Protection is on only with an Admin PIN, so a Cashier PIN left without one can't unlock POS.
        guard pins[.admin] != nil else {
            return []
        }
        return POSLocalRole.allCases.compactMap { role in
            pins[role].map { POSPINCredential(staff: role.staff, pinHash: $0) }
        }
    }

    func configuredRoles() throws(POSPINStoreError) -> Set<POSLocalRole> {
        let pins = try loadPINs()
        return pins[.admin] == nil ? [] : Set(pins.keys)
    }

    /// Runs up to two PBKDF2 derivations, so call it off the main actor.
    func setPIN(_ pin: String, for role: POSLocalRole) throws(POSPINStoreError) {
        guard Self.isValidPIN(pin) else {
            throw .invalidPINFormat
        }
        var pins = try loadPINs()
        if role != .admin, pins[.admin] == nil {
            throw .adminPINRequired
        }
        // Each PIN must identify one role.
        if pins.contains(where: { $0.key != role && $0.value.matches(pin) }) {
            throw .pinMatchesOtherRole
        }
        guard let hash = POSPINHash(pin: pin, iterations: iterations) else {
            throw .storageFailure
        }
        pins[role] = hash
        try savePINs(pins)
    }

    /// Removing the Admin PIN also removes the Cashier PIN, which turns protection off.
    func removePIN(for role: POSLocalRole) throws(POSPINStoreError) {
        guard role != .admin else {
            try savePINs([:])
            return
        }
        var pins = try loadPINs()
        pins[role] = nil
        try savePINs(pins)
    }

    /// Removes the local PINs of every store, for logout.
    static func removeAll(storage: POSSecureStorage = KeychainPOSSecureStorage()) throws {
        try storage.removeAll()
    }
}

private extension POSLocalPINStore {
    var key: String {
        "pins.\(siteID)"
    }

    static func isValidPIN(_ pin: String) -> Bool {
        pin.count == Constants.pinLength && pin.allSatisfy { $0.isASCII && $0.isNumber }
    }

    func loadPINs() throws(POSPINStoreError) -> [POSLocalRole: POSPINHash] {
        do {
            guard let data = try storage.data(forKey: key) else {
                return [:]
            }
            let stored = try JSONDecoder().decode([String: POSPINHash].self, from: data)
            return Dictionary(uniqueKeysWithValues: stored.compactMap { rawRole, hash in
                POSLocalRole(rawValue: rawRole).map { ($0, hash) }
            })
        } catch {
            DDLogError("⛔️ POS local PINs: reading failed for site \(siteID): \(error)")
            throw .storageFailure
        }
    }

    func savePINs(_ pins: [POSLocalRole: POSPINHash]) throws(POSPINStoreError) {
        do {
            let stored = Dictionary(uniqueKeysWithValues: pins.map { ($0.key.rawValue, $0.value) })
            let data = pins.isEmpty ? nil : try JSONEncoder().encode(stored)
            try POSPINAttemptContext.withLogoutEpoch(scopeID: storage.scopeID, epoch: logoutEpoch) {
                try storage.setData(data, forKey: key)
            }
        } catch {
            DDLogError("⛔️ POS local PINs: saving failed for site \(siteID): \(error)")
            throw .storageFailure
        }
    }

    enum Constants {
        static let pinLength = 4
    }
}

protocol POSSecureStorage: Sendable {
    var scopeID: String { get }
    func data(forKey key: String) throws -> Data?
    /// Removes the entry when `data` is `nil`.
    func setData(_ data: Data?, forKey key: String) throws
    func removeAll() throws
}

struct KeychainPOSSecureStorage: POSSecureStorage {
    static let service = "com.automattic.woocommerce.pos.localPINs"

    private let service: String
    var scopeID: String { service }

    init(service: String = KeychainPOSSecureStorage.service) {
        self.service = service
    }

    func data(forKey key: String) throws -> Data? {
        try keychain.getData(key)
    }

    func setData(_ data: Data?, forKey key: String) throws {
        if let data {
            try keychain.set(data, key: key)
        } else {
            try keychain.remove(key)
        }
    }

    func removeAll() throws {
        try keychain.removeAll()
    }

    // `Keychain` isn't `Sendable`, so each call builds its own instead of storing one.
    // This-device-only items are left out of backups and don't move to another device.
    private var keychain: Keychain {
        Keychain(service: service).accessibility(.whenUnlockedThisDeviceOnly)
    }
}
