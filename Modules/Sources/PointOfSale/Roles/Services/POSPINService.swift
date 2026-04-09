import Foundation
import CryptoKit

/// Identifies the role a PIN is associated with.
public enum PINRole: String, CaseIterable, Sendable {
    case manager
    case cashier
}

/// Protocol abstracting PIN storage so tests can inject in-memory storage.
protocol POSPINStoring {
    func store(_ value: String, forKey key: String)
    func retrieve(forKey key: String) -> String?
    func delete(forKey key: String)
}

/// Keychain-backed PIN storage using `kSecClassGenericPassword`.
final class KeychainPINStorage: POSPINStoring {
    private let service: String

    init(service: String = "com.woocommerce.pos.pins") {
        self.service = service
    }

    func store(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }

        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func retrieve(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// In-memory PIN storage for testing.
final class InMemoryPINStorage: POSPINStoring {
    private var storage: [String: String] = [:]

    func store(_ value: String, forKey key: String) {
        storage[key] = value
    }

    func retrieve(forKey key: String) -> String? {
        storage[key]
    }

    func delete(forKey key: String) {
        storage[key] = nil
    }
}

/// Manages POS PINs with SHA-256 hashing and configurable storage backend.
public final class POSPINService {
    private let storage: POSPINStoring

    /// Creates a POS PIN service with the default Keychain-backed storage.
    public convenience init() {
        self.init(storage: KeychainPINStorage())
    }

    init(storage: POSPINStoring) {
        self.storage = storage
    }

    /// Validates that the PIN is 4-6 digits.
    public func isValidFormat(_ pin: String) -> Bool {
        let pattern = #"^\d{4,6}$"#
        return pin.range(of: pattern, options: .regularExpression) != nil
    }

    /// Stores a SHA-256 hashed PIN for the given role.
    public func setPIN(_ pin: String, for role: PINRole) {
        let hash = hashPIN(pin)
        storage.store(hash, forKey: role.rawValue)
    }

    /// Verifies a PIN against the stored hash for a specific role.
    public func verifyPIN(_ pin: String, for role: PINRole) -> Bool {
        guard let storedHash = storage.retrieve(forKey: role.rawValue) else {
            return false
        }
        return hashPIN(pin) == storedHash
    }

    /// Checks all roles and returns the matching role, or nil if no match.
    public func verifyPIN(_ pin: String) -> PINRole? {
        for role in PINRole.allCases {
            if verifyPIN(pin, for: role) {
                return role
            }
        }
        return nil
    }

    /// Whether a PIN is configured for the given role.
    public func hasPIN(for role: PINRole) -> Bool {
        storage.retrieve(forKey: role.rawValue) != nil
    }

    /// Removes the PIN for the given role.
    public func deletePIN(for role: PINRole) {
        storage.delete(forKey: role.rawValue)
    }

    // MARK: - Private

    private func hashPIN(_ pin: String) -> String {
        let data = Data(pin.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
