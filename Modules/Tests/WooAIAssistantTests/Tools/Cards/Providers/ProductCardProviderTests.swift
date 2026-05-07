import Foundation
import Fakes
import Testing
import Yosemite
import YosemiteTestHelpers
@testable import WooAIAssistant

private let productTestSiteID: Int64 = 123

@MainActor
struct ProductCardProviderTests {

    @Test
    func test_fetch_when_all_in_storage_then_no_remote_call() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: makeProduct(id: 1))
        storageManager.insertSampleProduct(readOnlyProduct: makeProduct(id: 2))
        let dispatched = DispatchedProductActions()
        let provider = ProductCardProvider(siteID: productTestSiteID,
                                           storageManager: storageManager,
                                           dispatchAction: { dispatched.append($0) })
        let refs = [makeProductRef(1), makeProductRef(2)]

        // When
        let outcomes = await provider.fetch(refs: refs)

        // Then
        #expect(outcomes.count == 2)
        #expect(isResolvedProduct(outcomes[refs[0]], id: 1))
        #expect(isResolvedProduct(outcomes[refs[1]], id: 2))
        #expect(dispatched.actions.isEmpty)
    }

    @Test
    func test_fetch_when_none_in_storage_then_remote_called_for_all() async {
        // Given
        let storageManager = MockStorageManager()
        let dispatched = DispatchedProductActions()
        let provider = ProductCardProvider(siteID: productTestSiteID,
                                           storageManager: storageManager,
                                           dispatchAction: { action in
            dispatched.append(action)
            guard let productAction = action as? ProductAction,
                  case .retrieveProducts(_, let ids, _, _, let onCompletion) = productAction else { return }
            onCompletion(.success((products: ids.map { makeProduct(id: $0) }, hasNextPage: false)))
        })
        let refs = [makeProductRef(10), makeProductRef(11)]

        // When
        let outcomes = await provider.fetch(refs: refs)

        // Then
        #expect(dispatched.count == 1)
        #expect(isResolvedProduct(outcomes[refs[0]], id: 10))
        #expect(isResolvedProduct(outcomes[refs[1]], id: 11))
    }

    @Test
    func test_fetch_when_mixed_then_remote_called_only_for_misses() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: makeProduct(id: 1))
        let dispatched = DispatchedProductActions()
        let provider = ProductCardProvider(siteID: productTestSiteID,
                                           storageManager: storageManager,
                                           dispatchAction: { action in
            dispatched.append(action)
            guard let productAction = action as? ProductAction,
                  case .retrieveProducts(_, let ids, _, _, let onCompletion) = productAction else { return }
            onCompletion(.success((products: ids.map { makeProduct(id: $0) }, hasNextPage: false)))
        })
        let refs = [makeProductRef(1), makeProductRef(2)]

        // When
        let outcomes = await provider.fetch(refs: refs)

        // Then
        #expect(dispatched.count == 1)
        #expect(dispatched.lastRetrieveProductsIDs == [2])
        #expect(isResolvedProduct(outcomes[refs[0]], id: 1))
        #expect(isResolvedProduct(outcomes[refs[1]], id: 2))
    }

    @Test
    func test_fetch_when_remote_fails_then_storage_hits_still_resolve() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: makeProduct(id: 1))
        let provider = ProductCardProvider(siteID: productTestSiteID,
                                           storageManager: storageManager,
                                           dispatchAction: { action in
            guard let productAction = action as? ProductAction,
                  case .retrieveProducts(_, _, _, _, let onCompletion) = productAction else { return }
            onCompletion(.failure(SampleError.boom))
        })
        let refs = [makeProductRef(1), makeProductRef(99)]

        // When
        let outcomes = await provider.fetch(refs: refs)

        // Then
        #expect(isResolvedProduct(outcomes[refs[0]], id: 1))
        #expect(isRejected(outcomes[refs[1]], reason: .fetchFailed))
    }

    @Test
    func test_fetch_when_action_returns_subset_then_missing_ids_rejected_as_notFound() async {
        // Given
        let storageManager = MockStorageManager()
        let provider = ProductCardProvider(siteID: productTestSiteID,
                                           storageManager: storageManager,
                                           dispatchAction: { action in
            guard let productAction = action as? ProductAction,
                  case .retrieveProducts(_, let ids, _, _, let onCompletion) = productAction else { return }
            let returned = ids.filter { $0 == 10 }
            onCompletion(.success((products: returned.map { makeProduct(id: $0) }, hasNextPage: false)))
        })
        let refs = [makeProductRef(10), makeProductRef(11)]

        // When
        let outcomes = await provider.fetch(refs: refs)

        // Then
        #expect(isResolvedProduct(outcomes[refs[0]], id: 10))
        #expect(isRejected(outcomes[refs[1]], reason: .notFound))
    }

    @Test
    func test_fetch_when_storage_entry_is_trash_then_rejected_as_staleReference() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: makeProduct(id: 1).copy(statusKey: "trash"))
        let provider = ProductCardProvider(siteID: productTestSiteID,
                                           storageManager: storageManager,
                                           dispatchAction: { _ in })

        // When
        let outcomes = await provider.fetch(refs: [makeProductRef(1)])

        // Then
        #expect(isRejected(outcomes[makeProductRef(1)], reason: .staleReference))
    }
}

private func makeProduct(id: Int64) -> Product {
    Product.fake().copy(siteID: productTestSiteID,
                        productID: id,
                        name: "Item \(id)",
                        statusKey: "publish",
                        sku: "SKU-\(id)",
                        price: "10.00",
                        stockStatusKey: "instock")
}

private func makeProductRef(_ id: Int64) -> CardRef {
    CardRef(family: .product, id: id, parentID: 0)
}

private func isResolvedProduct(_ outcome: CardEntityOutcome?, id: Int64) -> Bool {
    guard case .found(.product(let payload)) = outcome else { return false }
    return payload.id == id
}

private func isRejected(_ outcome: CardEntityOutcome?, reason: CardRefRejectionReason) -> Bool {
    guard case .rejected(let actual) = outcome else { return false }
    return actual == reason
}

private final class DispatchedProductActions: @unchecked Sendable {
    nonisolated(unsafe) private(set) var actions: [Action] = []

    var count: Int { actions.count }

    var lastRetrieveProductsIDs: [Int64] {
        guard let productAction = actions.last as? ProductAction,
              case .retrieveProducts(_, let ids, _, _, _) = productAction else { return [] }
        return ids
    }

    func append(_ action: Action) { actions.append(action) }
}

private enum SampleError: Error { case boom }
