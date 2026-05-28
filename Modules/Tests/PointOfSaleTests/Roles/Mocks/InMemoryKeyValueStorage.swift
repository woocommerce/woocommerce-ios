import Foundation
@testable import PointOfSale

/// In-memory `POSStaffKeyValueStorage` for tests. Single-threaded use under main-actor-isolated
/// test suites; not safe for concurrent access.
final class InMemoryKeyValueStorage: POSStaffKeyValueStorage, @unchecked Sendable {
    private var store: [String: String] = [:]

    func string(forKey key: String) -> String? { store[key] }
    func setString(_ value: String?, forKey key: String) {
        if let value { store[key] = value } else { store.removeValue(forKey: key) }
    }
}
