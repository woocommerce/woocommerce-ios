import Foundation
import Synchronization
@testable import PointOfSale

final class InMemoryPOSSecureStorage: POSSecureStorage, Sendable {
    private struct State {
        var values: [String: Data] = [:]
        var shouldFail = false
    }

    private let state = Mutex(State())

    var values: [String: Data] {
        state.withLock { $0.values }
    }

    var shouldFail: Bool {
        get { state.withLock { $0.shouldFail } }
        set { state.withLock { $0.shouldFail = newValue } }
    }

    func data(forKey key: String) throws -> Data? {
        try state.withLock { state in
            try Self.failIfNeeded(state)
            return state.values[key]
        }
    }

    func setData(_ data: Data?, forKey key: String) throws {
        try state.withLock { state in
            try Self.failIfNeeded(state)
            state.values[key] = data
        }
    }

    func removeAll() throws {
        try state.withLock { state in
            try Self.failIfNeeded(state)
            state.values = [:]
        }
    }

    private static func failIfNeeded(_ state: State) throws {
        if state.shouldFail {
            throw NSError(domain: "InMemoryPOSSecureStorage", code: -1)
        }
    }
}
