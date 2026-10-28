import Foundation
import Synchronization
import Testing
import YosemiteTestHelpers
@testable import Yosemite
@testable import Networking
@testable import Storage

@Suite(.timeLimit(.minutes(5)))
@MainActor
struct OrderStoreLifetimeTests {
    @Test func test_synchronize_orders_when_store_is_released_then_request_and_write_complete() async {
        // Given
        let storageManager = MockStorageManager()
        let network = MockNetwork()
        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")
        let dispatcher = Dispatcher()
        var store: OrderStore? = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let storeWasReleased = { [weak store] in store == nil }

        // When
        let error: Error? = await withCheckedContinuation { continuation in
            store?.onAction(OrderAction.synchronizeOrders(siteID: 123, statuses: nil, pageNumber: 1, pageSize: 75) { _, error in
                continuation.resume(returning: error)
            })
            store = nil
            #expect(storeWasReleased())
        }

        // Then
        #expect(storeWasReleased())
        #expect(error == nil)
        #expect(storageManager.viewStorage.countObjects(ofType: Storage.Order.self) == 4)
        #expect(dispatcher.processor(for: OrderAction.self) == nil)
    }

    @Test func test_retrieve_order_when_store_is_released_before_queued_write_then_skips_write_and_completes() async throws {
        // Given
        let queuedWrites = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let completions = AsyncStream<Result<Yosemite.Order, Error>>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let storageManager = MockQueuedOrderStorageManager(onWriteQueued: { queuedWrites.continuation.yield(()) })
        let network = MockNetwork()
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")
        var store: OrderStore? = OrderStore(dispatcher: Dispatcher(), storageManager: storageManager, network: network)

        // When
        store?.onAction(OrderAction.retrieveOrderRemotely(siteID: 123, orderID: 963) { value in
            completions.continuation.yield(value)
        })
        var queuedWriteIterator = queuedWrites.stream.makeAsyncIterator()
        let queuedWrite: Void? = await queuedWriteIterator.next()
        try #require(queuedWrite != nil)
        store = nil
        storageManager.flushWrites()
        var completionIterator = completions.stream.makeAsyncIterator()
        let result = await completionIterator.next()

        // Then
        let retrievedOrder = try #require(result).get()
        #expect(retrievedOrder.orderID == 963)
        #expect(storageManager.viewStorage.countObjects(ofType: Storage.Order.self) == 0)
    }
}

/// Holds non-generic storage operations until the test releases the Store, without retaining its request handler.
private final class MockQueuedOrderStorageManager: StorageManagerType, Sendable {
    private struct Write: Sendable {
        let operation: @Sendable (StorageType) -> Void
        let completion: (@Sendable () -> Void)?
        let queue: DispatchQueue
    }

    private let underlying = MockStorageManager()
    private let writes = Mutex<[Write]>([])
    private let onWriteQueued: @Sendable () -> Void

    var viewStorage: StorageType { underlying.viewStorage }

    init(onWriteQueued: @escaping @Sendable () -> Void) {
        self.onWriteQueued = onWriteQueued
    }

    func performAndSave(_ operation: @escaping @Sendable (StorageType) -> Void,
                        completion: (@Sendable () -> Void)?,
                        on queue: DispatchQueue) {
        writes.withLock { $0.append(Write(operation: operation, completion: completion, queue: queue)) }
        onWriteQueued()
    }

    func performAndSave<T>(_ operation: @escaping @Sendable (StorageType) throws -> T,
                           completion: @escaping @Sendable (Result<T, Error>) -> Void,
                           on queue: DispatchQueue) {
        underlying.performAndSave(operation, completion: completion, on: queue)
    }

    func reset(onCompletion: (@Sendable () -> Void)?) {
        underlying.reset(onCompletion: onCompletion)
    }

    func flushWrites() {
        let pendingWrites = writes.withLock { pending in
            defer { pending.removeAll() }
            return pending
        }
        for write in pendingWrites {
            underlying.performAndSave(write.operation, completion: write.completion, on: write.queue)
        }
    }
}
