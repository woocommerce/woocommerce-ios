import Foundation
import Synchronization
@testable import PointOfSale

final class InMemoryPOSSecureStorage: POSSecureStorage, Sendable {
    let scopeID = UUID().uuidString
    private struct State {
        var values: [String: Data] = [:]
        var shouldFail = false
        var shouldFailWrites = false
        var shouldFailReadback = false
        var failNextRead = false
        var reads = 0
        var writes = 0
    }

    private let state = Mutex(State())

    var readCount: Int { state.withLock { $0.reads } }
    var writeCount: Int { state.withLock { $0.writes } }

    var values: [String: Data] {
        state.withLock { $0.values }
    }

    var shouldFail: Bool {
        get { state.withLock { $0.shouldFail } }
        set { state.withLock { $0.shouldFail = newValue } }
    }

    var shouldFailWrites: Bool {
        get { state.withLock { $0.shouldFailWrites } }
        set { state.withLock { $0.shouldFailWrites = newValue } }
    }

    var shouldFailReadback: Bool {
        get { state.withLock { $0.shouldFailReadback } }
        set { state.withLock { $0.shouldFailReadback = newValue } }
    }

    func data(forKey key: String) throws -> Data? {
        try state.withLock { state in
            state.reads += 1
            if state.failNextRead {
                state.failNextRead = false
                throw NSError(domain: "InMemoryPOSSecureStorage", code: -3)
            }
            try Self.failIfNeeded(state)
            return state.values[key]
        }
    }

    func setData(_ data: Data?, forKey key: String) throws {
        try state.withLock { state in
            state.writes += 1
            if state.shouldFailWrites { throw NSError(domain: "InMemoryPOSSecureStorage", code: -2) }
            try Self.failIfNeeded(state)
            state.values[key] = data
            state.failNextRead = state.shouldFailReadback
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
