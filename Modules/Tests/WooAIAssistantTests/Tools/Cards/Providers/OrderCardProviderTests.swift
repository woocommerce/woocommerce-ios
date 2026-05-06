import Foundation
import Fakes
import Testing
import Yosemite
import YosemiteTestHelpers
@testable import WooAIAssistant

private let orderTestSiteID: Int64 = 123

@MainActor
struct OrderCardProviderTests {

    @Test
    func test_fetch_when_all_in_storage_then_no_remote_call() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleOrder(readOnlyOrder: makeOrder(id: 1))
        storageManager.insertSampleOrder(readOnlyOrder: makeOrder(id: 2))
        let dispatched = DispatchedActions()
        let provider = OrderCardProvider(siteID: orderTestSiteID,
                                         storageManager: storageManager,
                                         dispatchAction: { dispatched.append($0) })
        let refs = [makeOrderRef(1), makeOrderRef(2)]

        // When
        let outcomes = await provider.fetch(refs: refs)

        // Then
        #expect(outcomes.count == 2)
        #expect(isResolvedOrder(outcomes[refs[0]], id: 1))
        #expect(isResolvedOrder(outcomes[refs[1]], id: 2))
        #expect(dispatched.actions.isEmpty)
    }

    @Test
    func test_fetch_when_none_in_storage_then_remote_called_for_all() async {
        // Given
        let storageManager = MockStorageManager()
        let dispatched = DispatchedActions()
        let provider = OrderCardProvider(siteID: orderTestSiteID,
                                         storageManager: storageManager,
                                         dispatchAction: { action in
            dispatched.append(action)
            guard let orderAction = action as? OrderAction,
                  case .retrieveOrders(_, let ids, let onCompletion) = orderAction else {
                Issue.record("expected retrieveOrders")
                return
            }
            for id in ids {
                storageManager.insertSampleOrder(readOnlyOrder: makeOrder(id: id))
            }
            onCompletion(.success(ids.map { makeOrder(id: $0) }))
        })
        let refs = [makeOrderRef(10), makeOrderRef(11)]

        // When
        let outcomes = await provider.fetch(refs: refs)

        // Then
        #expect(dispatched.count == 1)
        #expect(isResolvedOrder(outcomes[refs[0]], id: 10))
        #expect(isResolvedOrder(outcomes[refs[1]], id: 11))
    }

    @Test
    func test_fetch_when_mixed_then_remote_called_only_for_misses() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleOrder(readOnlyOrder: makeOrder(id: 1))
        let dispatched = DispatchedActions()
        let provider = OrderCardProvider(siteID: orderTestSiteID,
                                         storageManager: storageManager,
                                         dispatchAction: { action in
            dispatched.append(action)
            guard let orderAction = action as? OrderAction,
                  case .retrieveOrders(_, let ids, let onCompletion) = orderAction else { return }
            for id in ids {
                storageManager.insertSampleOrder(readOnlyOrder: makeOrder(id: id))
            }
            onCompletion(.success(ids.map { makeOrder(id: $0) }))
        })
        let refs = [makeOrderRef(1), makeOrderRef(2)]

        // When
        let outcomes = await provider.fetch(refs: refs)

        // Then
        #expect(dispatched.count == 1)
        #expect(dispatched.lastRetrieveOrdersIDs == [2])
        #expect(isResolvedOrder(outcomes[refs[0]], id: 1))
        #expect(isResolvedOrder(outcomes[refs[1]], id: 2))
    }

    @Test
    func test_fetch_when_remote_fails_then_storage_hits_still_resolve() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleOrder(readOnlyOrder: makeOrder(id: 1))
        let provider = OrderCardProvider(siteID: orderTestSiteID,
                                         storageManager: storageManager,
                                         dispatchAction: { action in
            guard let orderAction = action as? OrderAction,
                  case .retrieveOrders(_, _, let onCompletion) = orderAction else { return }
            onCompletion(.failure(SampleError.boom))
        })
        let refs = [makeOrderRef(1), makeOrderRef(99)]

        // When
        let outcomes = await provider.fetch(refs: refs)

        // Then
        #expect(isResolvedOrder(outcomes[refs[0]], id: 1))
        #expect(isRejected(outcomes[refs[1]], reason: .fetchFailed))
    }

    @Test
    func test_fetch_when_action_returns_subset_then_missing_ids_rejected_as_notFound() async {
        // Given
        let storageManager = MockStorageManager()
        let provider = OrderCardProvider(siteID: orderTestSiteID,
                                         storageManager: storageManager,
                                         dispatchAction: { action in
            guard let orderAction = action as? OrderAction,
                  case .retrieveOrders(_, let ids, let onCompletion) = orderAction else { return }
            // Server returns only one of the two requested ids.
            let returned = ids.filter { $0 == 10 }
            for id in returned {
                storageManager.insertSampleOrder(readOnlyOrder: makeOrder(id: id))
            }
            onCompletion(.success(returned.map { makeOrder(id: $0) }))
        })
        let refs = [makeOrderRef(10), makeOrderRef(11)]

        // When
        let outcomes = await provider.fetch(refs: refs)

        // Then
        #expect(isResolvedOrder(outcomes[refs[0]], id: 10))
        #expect(isRejected(outcomes[refs[1]], reason: .notFound))
    }

    @Test
    func test_fetch_when_storage_entry_is_trash_then_rejected_as_staleReference() async {
        // Given
        let storageManager = MockStorageManager()
        let trashed = makeOrder(id: 1).copy(status: .custom("trash"))
        storageManager.insertSampleOrder(readOnlyOrder: trashed)
        let provider = OrderCardProvider(siteID: orderTestSiteID,
                                         storageManager: storageManager,
                                         dispatchAction: { _ in })

        // When
        let outcomes = await provider.fetch(refs: [makeOrderRef(1)])

        // Then
        #expect(isRejected(outcomes[makeOrderRef(1)], reason: .staleReference))
    }
}

private func makeOrder(id: Int64) -> Order {
    Order.fake().copy(siteID: orderTestSiteID,
                      orderID: id,
                      number: "\(id)",
                      status: .processing,
                      dateCreated: Date(timeIntervalSince1970: 1_700_000_000))
}

private func makeOrderRef(_ id: Int64) -> CardRef {
    CardRef(family: .order, id: id, parentID: 0)
}

private func isResolvedOrder(_ outcome: CardEntityOutcome?, id: Int64) -> Bool {
    guard case .found(.order(let payload)) = outcome else { return false }
    return payload.id == id
}

private func isRejected(_ outcome: CardEntityOutcome?, reason: CardRefRejectionReason) -> Bool {
    guard case .rejected(let actual) = outcome else { return false }
    return actual == reason
}

private final class DispatchedActions: @unchecked Sendable {
    nonisolated(unsafe) private(set) var actions: [Action] = []

    var count: Int { actions.count }

    var lastRetrieveOrdersIDs: [Int64] {
        guard let orderAction = actions.last as? OrderAction,
              case .retrieveOrders(_, let ids, _) = orderAction else { return [] }
        return ids
    }

    func append(_ action: Action) { actions.append(action) }
}

private enum SampleError: Error { case boom }
