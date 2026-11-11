import Foundation
@testable import PointOfSale

final class InMemoryPOSSecureStorage: POSSecureStorage, @unchecked Sendable {
    private(set) var values: [String: Data] = [:]
    var shouldFail = false

    func data(forKey key: String) throws -> Data? {
        try failIfNeeded()
        return values[key]
    }

    func setData(_ data: Data?, forKey key: String) throws {
        try failIfNeeded()
        values[key] = data
    }

    func removeAll() throws {
        try failIfNeeded()
        values = [:]
    }

    private func failIfNeeded() throws {
        if shouldFail {
            throw NSError(domain: "InMemoryPOSSecureStorage", code: -1)
        }
    }
}
