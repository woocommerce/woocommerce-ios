import Foundation
import struct Networking.POSStaffMember

/// Protocol abstracting staff-list storage so tests can inject in-memory storage.
public protocol POSStaffCaching {
    func load() -> [POSStaffMember]
    func save(_ members: [POSStaffMember]) throws
    func clear()
}

/// Keychain-backed cache for the `/wc-pos/v1/staff` response.
///
/// The fetched list contains PBKDF2 hashes (security-sensitive enough that a
/// device thief with a stolen hash could brute-force a 4-digit PIN in seconds),
/// so the cache lives in the Keychain rather than UserDefaults. Stored as a
/// single JSON-encoded blob under `kSecClassGenericPassword`.
public final class POSStaffCache: POSStaffCaching {
    private let service: String
    private let account: String

    public init(service: String = "com.woocommerce.pos.staffCache",
                account: String = "default") {
        self.service = service
        self.account = account
    }

    /// Returns the cached staff list, or an empty array when the cache is empty
    /// or unreadable. Decode failures clear the slot so a stale/corrupted entry
    /// can be replaced by the next successful fetch.
    public func load() -> [POSStaffMember] {
        guard let data = readKeychainData() else { return [] }
        do {
            return try JSONDecoder().decode([POSStaffMember].self, from: data)
        } catch {
            clear()
            return []
        }
    }

    public func save(_ members: [POSStaffMember]) throws {
        let data = try JSONEncoder().encode(members)
        writeKeychainData(data)
    }

    public func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Keychain primitives

    private func readKeychainData() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return data
    }

    private func writeKeychainData(_ data: Data) {
        clear()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
}

/// In-memory cache for tests and previews.
public final class InMemoryPOSStaffCache: POSStaffCaching {
    private var members: [POSStaffMember] = []

    public init(initial: [POSStaffMember] = []) {
        self.members = initial
    }

    public func load() -> [POSStaffMember] {
        members
    }

    public func save(_ members: [POSStaffMember]) throws {
        self.members = members
    }

    public func clear() {
        members = []
    }
}
