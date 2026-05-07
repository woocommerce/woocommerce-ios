import Foundation
import Fakes
import Testing
import Yosemite
import YosemiteTestHelpers
@testable import WooAIAssistant

private let productTestSiteID: Int64 = 123

@MainActor
struct AssistantProductsDataSourceTests {

    @Test
    func test_fetch_when_all_in_storage_then_no_remote_call() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: makeProduct(id: 1))
        storageManager.insertSampleProduct(readOnlyProduct: makeProduct(id: 2))
        let dispatched = DispatchedProductActions()
        let dataSource = AssistantProductsDataSource(siteID: productTestSiteID,
                                           storageManager: storageManager,
                                           dispatchAction: { dispatched.append($0) })
        let refs = [makeProductRef(1), makeProductRef(2)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

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
        let dataSource = AssistantProductsDataSource(siteID: productTestSiteID,
                                           storageManager: storageManager,
                                           dispatchAction: { action in
            dispatched.append(action)
            guard let productAction = action as? ProductAction,
                  case .retrieveProducts(_, let ids, _, _, let onCompletion) = productAction else { return }
            onCompletion(.success((products: ids.map { makeProduct(id: $0) }, hasNextPage: false)))
        })
        let refs = [makeProductRef(10), makeProductRef(11)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

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
        let dataSource = AssistantProductsDataSource(siteID: productTestSiteID,
                                           storageManager: storageManager,
                                           dispatchAction: { action in
            dispatched.append(action)
            guard let productAction = action as? ProductAction,
                  case .retrieveProducts(_, let ids, _, _, let onCompletion) = productAction else { return }
            onCompletion(.success((products: ids.map { makeProduct(id: $0) }, hasNextPage: false)))
        })
        let refs = [makeProductRef(1), makeProductRef(2)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

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
        let dataSource = AssistantProductsDataSource(siteID: productTestSiteID,
                                           storageManager: storageManager,
                                           dispatchAction: { action in
            guard let productAction = action as? ProductAction,
                  case .retrieveProducts(_, _, _, _, let onCompletion) = productAction else { return }
            onCompletion(.failure(SampleError.boom))
        })
        let refs = [makeProductRef(1), makeProductRef(99)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

        // Then
        #expect(isResolvedProduct(outcomes[refs[0]], id: 1))
        #expect(isRejected(outcomes[refs[1]], reason: .fetchFailed))
    }

    @Test
    func test_fetch_when_action_returns_subset_then_missing_ids_rejected_as_notFound() async {
        // Given
        let storageManager = MockStorageManager()
        let dataSource = AssistantProductsDataSource(siteID: productTestSiteID,
                                           storageManager: storageManager,
                                           dispatchAction: { action in
            guard let productAction = action as? ProductAction,
                  case .retrieveProducts(_, let ids, _, _, let onCompletion) = productAction else { return }
            let returned = ids.filter { $0 == 10 }
            onCompletion(.success((products: returned.map { makeProduct(id: $0) }, hasNextPage: false)))
        })
        let refs = [makeProductRef(10), makeProductRef(11)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

        // Then
        #expect(isResolvedProduct(outcomes[refs[0]], id: 10))
        #expect(isRejected(outcomes[refs[1]], reason: .notFound))
    }

    @Test
    func test_fetch_when_storage_entry_is_trash_then_rejected_as_staleReference() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: makeProduct(id: 1).copy(statusKey: "trash"))
        let dataSource = AssistantProductsDataSource(siteID: productTestSiteID,
                                           storageManager: storageManager,
                                           dispatchAction: { _ in })

        // When
        let outcomes = await dataSource.fetch(refs: [makeProductRef(1)])

        // Then
        #expect(isRejected(outcomes[makeProductRef(1)], reason: .staleReference))
    }

    @Test
    func test_updateProduct_when_cached_product_exists_then_refreshes_remote_before_update() async throws {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: makeProduct(id: 12).copy(name: "Cached name"))
        var updatedFields: ProductUpdateFields?
        let dataSource = AssistantProductsDataSource(siteID: productTestSiteID,
                                                     storageManager: storageManager,
                                                     dispatchAction: { action in
            guard let productAction = action as? ProductAction else { return }
            switch productAction {
            case .retrieveProduct(_, let productID, let onCompletion):
                onCompletion(.success(makeProduct(id: productID).copy(name: "Remote name")))
            case .updateProductFields(_, let productID, let fields, let onCompletion):
                updatedFields = fields
                onCompletion(.success(makeProduct(id: productID).copy(name: "Remote name", regularPrice: fields.regularPrice)))
            default:
                break
            }
        })

        // When
        let result = await dataSource.updateProduct(id: 12,
                                                    patch: ProductUpdatePatch(name: nil,
                                                                              regularPrice: "19.99",
                                                                              salePrice: nil,
                                                                              stockQuantity: nil,
                                                                              status: nil))

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(updatedFields?.regularPrice == "19.99")
    }

    @Test
    func test_bulkUpdateProducts_when_many_ids_then_fetches_all_ids_before_price_update() async throws {
        // Given
        let ids = Array(Int64(1)...Int64(30))
        let storageManager = MockStorageManager()
        let dispatched = DispatchedProductActions()
        let dataSource = AssistantProductsDataSource(siteID: productTestSiteID,
                                                     storageManager: storageManager,
                                                     dispatchAction: { action in
            dispatched.append(action)
            guard let productAction = action as? ProductAction else { return }
            switch productAction {
            case .retrieveProducts(_, let ids, _, _, let onCompletion):
                onCompletion(.success((products: ids.map { makeProduct(id: $0) }, hasNextPage: false)))
            case .updateProductFields(_, let productID, _, let onCompletion):
                onCompletion(.success(makeProduct(id: productID)))
            default:
                break
            }
        })

        // When
        let result = await dataSource.bulkUpdateProducts(ids: ids,
                                                         patch: ProductUpdatePatch(name: nil,
                                                                                   regularPrice: "19.99",
                                                                                   salePrice: nil,
                                                                                   stockQuantity: nil,
                                                                                   status: nil))

        // Then
        guard case .success(let writeResult) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(writeResult.updatedIDs == ids)
        #expect(dispatched.firstRetrieveProductsPageSize == ids.count)
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

@MainActor
private final class DispatchedProductActions {
    private(set) var actions: [Action] = []

    var count: Int { actions.count }

    var lastRetrieveProductsIDs: [Int64] {
        guard let productAction = actions.last as? ProductAction,
              case .retrieveProducts(_, let ids, _, _, _) = productAction else { return [] }
        return ids
    }

    var firstRetrieveProductsPageSize: Int? {
        for action in actions {
            guard let productAction = action as? ProductAction,
                  case .retrieveProducts(_, _, _, let pageSize, _) = productAction else { continue }
            return pageSize
        }
        return nil
    }

    func append(_ action: Action) { actions.append(action) }
}

private enum SampleError: Error { case boom }
