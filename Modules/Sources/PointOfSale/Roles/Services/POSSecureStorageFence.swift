import Foundation
import Synchronization

enum POSSecureStorageFence {
    private static let generations = Mutex<[String: UUID]>([:])

    static func currentGeneration(of service: String) -> UUID {
        generations.withLock { generations in
            if let generation = generations[service] {
                return generation
            }
            let generation = UUID()
            generations[service] = generation
            return generation
        }
    }

    static func isCurrent(_ generation: UUID, of service: String) -> Bool {
        generations.withLock { $0[service] == generation }
    }

    static func write(_ generation: UUID, to service: String, operation: () throws -> Void) throws {
        try generations.withLock { generations in
            guard generations[service] == generation else {
                throw POSPINStoreError.storageFailure
            }
            try operation()
        }
    }

    static func clear(_ service: String, operation: () throws -> Void) throws {
        try generations.withLock { generations in
            generations[service] = UUID()
            try operation()
        }
    }
}
