import Foundation
import Synchronization
import Testing
import YosemiteTestHelpers
@testable import Networking
@testable import Storage
@testable import Yosemite

@MainActor
struct ShippingLabelStoreConcurrencyTests {
    enum StoreKind: CaseIterable, Sendable {
        case legacy
        case wooShipping
    }

    @Test(arguments: StoreKind.allCases)
    func test_purchase_when_store_released_before_delay_then_does_not_poll(kind: StoreKind) {
        // Given
        let fixture = Fixture(kind: kind)
        var store: Store? = fixture.makeStore()
        weak let releasedStore = store
        let completions = Mutex(0)
        fixture.dispatcher.dispatch(fixture.purchaseAction { _ in completions.withLock { $0 += 1 } })
        #expect(fixture.scheduler.delays == [2])

        // When
        store = nil
        fixture.scheduler.runNext()

        // Then
        #expect(releasedStore == nil)
        #expect(fixture.statusCalls == 0)
        #expect(completions.withLock { $0 } == 0)
    }

    @Test(arguments: StoreKind.allCases)
    func test_purchase_when_status_stays_in_progress_then_preserves_retry_budget(kind: StoreKind) async {
        // Given
        let fixture = Fixture(kind: kind)
        let store = fixture.makeStore()
        defer { withExtendedLifetime(store) {} }
        fixture.setStatus(.success(.purchaseInProgress))

        // When
        let result: Result<[Networking.ShippingLabel], Error> = await withCheckedContinuation { continuation in
            fixture.dispatcher.dispatch(fixture.purchaseAction { continuation.resume(returning: $0) })
            for _ in 0..<5 {
                fixture.scheduler.runNext()
            }
            #expect(fixture.statusCalls == 5)
            fixture.setStatus(.success(.purchased))
            fixture.scheduler.runNext()
        }

        // Then
        #expect((try? result.get()) == [fixture.label])
        #expect(fixture.statusCalls == 6)
        #expect(fixture.scheduler.delays == [2] + Array(repeating: 0.25, count: 5))
    }

    @Test(arguments: StoreKind.allCases)
    func test_purchase_when_status_requests_fail_then_exhausts_error_retries(kind: StoreKind) {
        // Given
        let fixture = Fixture(kind: kind)
        let store = fixture.makeStore()
        defer { withExtendedLifetime(store) {} }
        fixture.setStatus(.failure(NetworkError.timeout()))
        let results = Mutex<[Result<[Networking.ShippingLabel], Error>]>([])
        fixture.dispatcher.dispatch(fixture.purchaseAction { result in results.withLock { $0.append(result) } })

        // When
        for _ in 0..<4 {
            fixture.scheduler.runNext()
        }

        // Then
        #expect(fixture.statusCalls == 4)
        #expect(fixture.scheduler.delays == [2, 0.25, 0.25, 0.25])
        #expect(results.withLock { $0.count } == 1)
        let error = results.withLock { $0.first?.failure as? NetworkError }
        #expect(error == NetworkError.timeout())
    }

    @Test(arguments: StoreKind.allCases)
    func test_sync_when_store_released_before_write_then_skips_write_and_completes(kind: StoreKind) async {
        // Given
        let storage = DeferredShippingLabelStorage()
        await withCheckedContinuation { continuation in
            storage.base.performAndSave({ storage in
                let order = storage.insertNewObject(ofType: Storage.Order.self)
                order.siteID = 1
                order.orderID = 2
                order.statusKey = "processing"
            }, completion: { continuation.resume() }, on: .main)
        }
        let fixture = Fixture(kind: kind, storageManager: storage)
        var store: Store? = fixture.makeStore()
        weak let releasedStore = store

        // When
        let succeeded: Bool = await withCheckedContinuation { continuation in
            fixture.dispatcher.dispatch(fixture.syncAction { continuation.resume(returning: $0) })
            #expect(storage.hasPendingWrite)
            store = nil
            storage.runWrite()
        }

        // Then
        #expect(releasedStore == nil)
        #expect(succeeded)
        #expect(storage.viewStorage.countObjects(ofType: Storage.ShippingLabel.self) == 0)
        #expect(storage.viewStorage.countObjects(ofType: Storage.WooShippingShipment.self) == 0)
    }
}

private extension ShippingLabelStoreConcurrencyTests {
    @MainActor
    final class Fixture {
        let kind: StoreKind
        let dispatcher = Dispatcher()
        let scheduler = ShippingLabelTestScheduler()
        let legacyRemote = MockShippingLabelRemote()
        let wooRemote = MockWooShippingRemote()
        let storageManager: StorageManagerType
        let label = Networking.ShippingLabel.fake().copy(siteID: 1, orderID: 2, shippingLabelID: 3, status: .purchased)

        init(kind: StoreKind, storageManager: StorageManagerType = MockStorageManager()) {
            self.kind = kind
            self.storageManager = storageManager
            legacyRemote.whenPurchaseShippingLabel(siteID: 1, orderID: 2,
                                                  originAddress: .fake(), destinationAddress: .fake(), packages: [],
                                                  emailCustomerReceipt: false,
                                                  thenReturn: .success([.fake().copy(shippingLabelID: 3)]))
            wooRemote.whenPurchaseShippingLabel(siteID: 1, thenReturn: .success([.fake().copy(shippingLabelID: 3)]))
            legacyRemote.whenLoadingShippingLabels(siteID: 1, orderID: 2,
                                                  thenReturn: .success(.init(shippingLabels: [label], settings: .fake())))
            wooRemote.whenLoadingConfig(siteID: 1,
                                     thenReturn: .success(.fake().copy(shipments: [.fake().copy(shippingLabel: label)])))
            setStatus(.success(.purchased))
        }

        var statusCalls: Int {
            switch kind {
            case .legacy: legacyRemote.checkLabelStatusCallsCount
            case .wooShipping: wooRemote.checkLabelStatusCallsCount
            }
        }

        func makeStore() -> Store {
            let schedule: @Sendable (TimeInterval, @escaping @MainActor @Sendable () -> Void) -> Void = { [scheduler] delay, operation in
                scheduler.enqueue(delay: delay, operation: operation)
            }
            switch kind {
            case .legacy:
                return ShippingLabelStore(dispatcher: dispatcher, storageManager: storageManager, network: MockNetwork(),
                                          remote: legacyRemote, schedule: schedule)
            case .wooShipping:
                return WooShippingStore(dispatcher: dispatcher, storageManager: storageManager, network: MockNetwork(),
                                        remote: wooRemote, schedule: schedule)
            }
        }

        func purchaseAction(completion: @escaping @Sendable (Result<[Networking.ShippingLabel], Error>) -> Void) -> Action {
            switch kind {
            case .legacy:
                return ShippingLabelAction.purchaseShippingLabel(siteID: 1, orderID: 2,
                                                                 originAddress: .fake(), destinationAddress: .fake(), packages: [],
                                                                 emailCustomerReceipt: false, completion: completion, pollingDelay: 0.25)
            case .wooShipping:
                return WooShippingAction.purchaseShippingLabel(siteID: 1, orderID: 2,
                                                               originAddress: .fake(), destinationAddress: .fake(), package: .fake(),
                                                               markOrderComplete: false, pollingDelay: 0.25) { result in
                    completion(result.map { [$0] })
                }
            }
        }

        func syncAction(completion: @escaping @Sendable (Bool) -> Void) -> Action {
            switch kind {
            case .legacy:
                return ShippingLabelAction.synchronizeShippingLabels(siteID: 1, orderID: 2) { completion($0.isSuccess) }
            case .wooShipping:
                return WooShippingAction.syncShipments(siteID: 1, orderID: 2) { completion($0.isSuccess) }
            }
        }

        func setStatus(_ result: Result<ShippingLabelStatus, Error>) {
            let response = result.map { ShippingLabelStatusPollingResponse.purchased(label.copy(status: $0)) }
            legacyRemote.whenCheckLabelStatus(siteID: 1, orderID: 2, labelIDs: [3], thenReturn: response.map { [$0] })
            wooRemote.whenCheckLabelStatus(siteID: 1, thenReturn: response)
        }
    }
}

private final class ShippingLabelTestScheduler: Sendable {
    private struct State {
        var delays: [TimeInterval] = []
        var operations: [@MainActor @Sendable () -> Void] = []
    }

    private let state = Mutex(State())
    var delays: [TimeInterval] { state.withLock { $0.delays } }

    func enqueue(delay: TimeInterval, operation: @escaping @MainActor @Sendable () -> Void) {
        state.withLock {
            $0.delays.append(delay)
            $0.operations.append(operation)
        }
    }

    @MainActor
    func runNext() {
        let operation = state.withLock { $0.operations.isEmpty ? nil : $0.operations.removeFirst() }
        #expect(operation != nil)
        operation?()
    }
}

private final class DeferredShippingLabelStorage: StorageManagerType {
    private struct Write {
        let operation: @Sendable (StorageType) -> Void
        let completion: (@Sendable () -> Void)?
        let queue: DispatchQueue
    }

    let base = MockStorageManager()
    private let pendingWrite = Mutex<Write?>(nil)
    var viewStorage: StorageType { base.viewStorage }
    var hasPendingWrite: Bool { pendingWrite.withLock { $0 != nil } }

    func performAndSave(_ operation: @escaping @Sendable (StorageType) -> Void,
                        completion: (@Sendable () -> Void)?, on queue: DispatchQueue) {
        pendingWrite.withLock { $0 = Write(operation: operation, completion: completion, queue: queue) }
    }

    func performAndSave<T>(_ operation: @escaping @Sendable (StorageType) throws -> T,
                           completion: @escaping @Sendable (Result<T, Error>) -> Void, on queue: DispatchQueue) {
        base.performAndSave(operation, completion: completion, on: queue)
    }

    func reset(onCompletion: (@Sendable () -> Void)?) {
        base.reset(onCompletion: onCompletion)
    }

    func runWrite() {
        let write = pendingWrite.withLock { value in
            defer { value = nil }
            return value
        }
        #expect(write != nil)
        if let write {
            base.performAndSave(write.operation, completion: write.completion, on: write.queue)
        }
    }
}
