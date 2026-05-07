import Foundation
import Fakes
import Testing
import Yosemite
import YosemiteTestHelpers
@testable import WooAIAssistant

private let orderTestSiteID: Int64 = 123

@MainActor
struct AssistantOrdersDataSourceTests {

    @Test
    func test_fetch_when_all_in_storage_then_no_remote_call() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleOrder(readOnlyOrder: makeOrder(id: 1))
        storageManager.insertSampleOrder(readOnlyOrder: makeOrder(id: 2))
        let dispatched = DispatchedActions()
        let dataSource = AssistantOrdersDataSource(siteID: orderTestSiteID,
                                         storageManager: storageManager,
                                         dispatchAction: { dispatched.append($0) })
        let refs = [makeOrderRef(1), makeOrderRef(2)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

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
        let dataSource = AssistantOrdersDataSource(siteID: orderTestSiteID,
                                         storageManager: storageManager,
                                         dispatchAction: { action in
            dispatched.append(action)
            guard let orderAction = action as? OrderAction,
                  case .retrieveOrders(_, let ids, let onCompletion) = orderAction else {
                Issue.record("expected retrieveOrders")
                return
            }
            onCompletion(.success(ids.map { makeOrder(id: $0) }))
        })
        let refs = [makeOrderRef(10), makeOrderRef(11)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

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
        let dataSource = AssistantOrdersDataSource(siteID: orderTestSiteID,
                                         storageManager: storageManager,
                                         dispatchAction: { action in
            dispatched.append(action)
            guard let orderAction = action as? OrderAction,
                  case .retrieveOrders(_, let ids, let onCompletion) = orderAction else { return }
            onCompletion(.success(ids.map { makeOrder(id: $0) }))
        })
        let refs = [makeOrderRef(1), makeOrderRef(2)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

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
        let dataSource = AssistantOrdersDataSource(siteID: orderTestSiteID,
                                         storageManager: storageManager,
                                         dispatchAction: { action in
            guard let orderAction = action as? OrderAction,
                  case .retrieveOrders(_, _, let onCompletion) = orderAction else { return }
            onCompletion(.failure(SampleError.boom))
        })
        let refs = [makeOrderRef(1), makeOrderRef(99)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

        // Then
        #expect(isResolvedOrder(outcomes[refs[0]], id: 1))
        #expect(isRejected(outcomes[refs[1]], reason: .fetchFailed))
    }

    @Test
    func test_fetch_when_action_returns_subset_then_missing_ids_rejected_as_notFound() async {
        // Given
        let storageManager = MockStorageManager()
        let dataSource = AssistantOrdersDataSource(siteID: orderTestSiteID,
                                         storageManager: storageManager,
                                         dispatchAction: { action in
            guard let orderAction = action as? OrderAction,
                  case .retrieveOrders(_, let ids, let onCompletion) = orderAction else { return }
            let returned = ids.filter { $0 == 10 }
            onCompletion(.success(returned.map { makeOrder(id: $0) }))
        })
        let refs = [makeOrderRef(10), makeOrderRef(11)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

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
        let dataSource = AssistantOrdersDataSource(siteID: orderTestSiteID,
                                         storageManager: storageManager,
                                         dispatchAction: { _ in })

        // When
        let outcomes = await dataSource.fetch(refs: [makeOrderRef(1)])

        // Then
        #expect(isRejected(outcomes[makeOrderRef(1)], reason: .staleReference))
    }

    @Test
    func test_bulkUpdateOrders_when_lookup_fails_then_returns_failure_without_updating_cached_orders() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleOrder(readOnlyOrder: makeOrder(id: 1))
        let dispatched = DispatchedActions()
        let dataSource = AssistantOrdersDataSource(siteID: orderTestSiteID,
                                                   storageManager: storageManager,
                                                   dispatchAction: { action in
            dispatched.append(action)
            guard let orderAction = action as? OrderAction else { return }
            switch orderAction {
            case .retrieveOrders(_, _, let onCompletion):
                onCompletion(.failure(SampleError.boom))
            case .updateOrder(_, _, _, _, let onCompletion):
                onCompletion(.success(makeOrder(id: 1)))
            default:
                break
            }
        })

        // When
        let result = await dataSource.bulkUpdateOrders(ids: [1, 99],
                                                       patch: OrderUpdatePatch(status: "completed",
                                                                               customerNote: nil,
                                                                               billingEmail: nil))

        // Then
        guard case .failure(let error) = result,
              (error as? SampleError) == .boom else {
            Issue.record("Expected lookup failure to abort the batch before updates")
            return
        }
        #expect(dispatched.count == 1)
        #expect(dispatched.lastRetrieveOrdersIDs == [99])
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

@MainActor
private final class DispatchedActions {
    private(set) var actions: [Action] = []

    var count: Int { actions.count }

    var lastRetrieveOrdersIDs: [Int64] {
        guard let orderAction = actions.last as? OrderAction,
              case .retrieveOrders(_, let ids, _) = orderAction else { return [] }
        return ids
    }

    func append(_ action: Action) { actions.append(action) }
}

private enum SampleError: Error, Equatable { case boom }
