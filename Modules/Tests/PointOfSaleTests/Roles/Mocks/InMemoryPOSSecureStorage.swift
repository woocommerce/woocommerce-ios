import Foundation
import Synchronization
@testable import PointOfSale

final class InMemoryPOSSecureStorage: POSSecureStorage, Sendable {
    private struct State {
        var values: [String: Data] = [:]
        var shouldFail = false
        var shouldFailWrites = false
        var reads = 0
        var writes = 0
    }

    private final class Shared: Sendable {
        let service = UUID().uuidString
        let state = Mutex(State())
    }

    private let shared: Shared
    private let generation: UUID
    private var service: String { shared.service }

    convenience init() {
        self.init(shared: Shared())
    }

    private init(shared: Shared) {
        self.shared = shared
        self.generation = POSSecureStorageFence.currentGeneration(of: shared.service)
    }

    func reopened() -> InMemoryPOSSecureStorage {
        InMemoryPOSSecureStorage(shared: shared)
    }

    var isStale: Bool { !POSSecureStorageFence.isCurrent(generation, of: service) }

    var readCount: Int { shared.state.withLock { $0.reads } }
    var writeCount: Int { shared.state.withLock { $0.writes } }

    var values: [String: Data] {
        shared.state.withLock { $0.values }
    }

    var shouldFail: Bool {
        get { shared.state.withLock { $0.shouldFail } }
        set { shared.state.withLock { $0.shouldFail = newValue } }
    }

    var shouldFailWrites: Bool {
        get { shared.state.withLock { $0.shouldFailWrites } }
        set { shared.state.withLock { $0.shouldFailWrites = newValue } }
    }

    func data(forKey key: String) throws -> Data? {
        try shared.state.withLock { state in
            state.reads += 1
            try Self.failIfNeeded(state)
            return state.values[key]
        }
    }

    func setData(_ data: Data?, forKey key: String) throws {
        try POSSecureStorageFence.write(generation, to: service) {
            try shared.state.withLock { state in
                state.writes += 1
                if state.shouldFailWrites { throw NSError(domain: "InMemoryPOSSecureStorage", code: -2) }
                try Self.failIfNeeded(state)
                state.values[key] = data
            }
        }
    }

    func removeAll() throws {
        try POSSecureStorageFence.clear(service) {
            try shared.state.withLock { state in
                try Self.failIfNeeded(state)
                state.values = [:]
            }
        }
    }

    private static func failIfNeeded(_ state: State) throws {
        if state.shouldFail {
            throw NSError(domain: "InMemoryPOSSecureStorage", code: -1)
        }
    }
}
