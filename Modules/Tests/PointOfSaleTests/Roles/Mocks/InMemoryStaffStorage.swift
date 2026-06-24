@testable import PointOfSale

/// In-memory `POSStaffKeyValueStorage` for tests, so `POSStaffCache` contents stay isolated per test
/// (no shared keychain state). `@unchecked Sendable`: each test owns its instance and never shares
/// it across tasks.
final class InMemoryStaffStorage: POSStaffKeyValueStorage, @unchecked Sendable {
    private var store: [String: String] = [:]
    func string(forKey key: String) -> String? { store[key] }
    func setString(_ value: String?, forKey key: String) { store[key] = value }
    func removeAll() { store.removeAll() }
}
