import Foundation
import Synchronization
import YosemiteTestHelpers
@testable import Storage

final class MockDeferredStatsStorageManager: StorageManagerType, Sendable {
    private let storageManager: MockStorageManager
    private let onWriteQueued: @Sendable () -> Void
    private let pendingWrite = Mutex<(@Sendable () -> Void)?>(nil)

    init(storageManager: MockStorageManager, onWriteQueued: @escaping @Sendable () -> Void = {}) {
        self.storageManager = storageManager
        self.onWriteQueued = onWriteQueued
    }

    var viewStorage: StorageType { storageManager.viewStorage }

    var hasPendingWrite: Bool {
        pendingWrite.withLock { $0 != nil }
    }

    func performAndSave(_ operation: @escaping @Sendable (StorageType) -> Void,
                        completion: (@Sendable () -> Void)?,
                        on queue: DispatchQueue) {
        let storageManager = storageManager
        pendingWrite.withLock {
            precondition($0 == nil, "Execute the pending write before queuing another")
            $0 = { storageManager.performAndSave(operation, completion: completion, on: queue) }
        }
        onWriteQueued()
    }

    func performPendingWrite() {
        let write = pendingWrite.withLock {
            let write = $0
            $0 = nil
            return write
        }
        write?()
    }

    func performAndSave<T>(_ operation: @escaping @Sendable (StorageType) throws -> T,
                           completion: @escaping @Sendable (Result<T, Error>) -> Void,
                           on queue: DispatchQueue) {
        storageManager.performAndSave(operation, completion: completion, on: queue)
    }

    func reset(onCompletion: (@Sendable () -> Void)?) {
        storageManager.reset(onCompletion: onCompletion)
    }
}
