import Foundation
import Fakes
import Testing
import Yosemite
import YosemiteTestHelpers
@testable import WooAIAssistant

private let variationTestSiteID: Int64 = 123

@MainActor
struct AssistantProductVariationsDataSourceTests {

    @Test
    func test_fetch_when_all_in_storage_then_no_remote_call() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProductVariation(readOnlyProductVariation: makeVariation(id: 5, parentID: 1))
        let dispatched = DispatchedVariationActions()
        let dataSource = AssistantProductVariationsDataSource(siteID: variationTestSiteID,
                                             storageManager: storageManager,
                                             dispatchAction: { dispatched.append($0) })
        let refs = [makeVariationRef(5, parent: 1)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

        // Then
        #expect(isResolvedVariation(outcomes[refs[0]], id: 5, parentID: 1))
        #expect(dispatched.actions.isEmpty)
    }

    @Test
    func test_fetch_when_none_in_storage_then_remote_called_for_all() async {
        // Given
        let storageManager = MockStorageManager()
        let dispatched = DispatchedVariationActions()
        let dataSource = AssistantProductVariationsDataSource(siteID: variationTestSiteID,
                                             storageManager: storageManager,
                                             dispatchAction: { action in
            dispatched.append(action)
            guard let variationAction = action as? ProductVariationAction,
                  case .retrieveProductVariation(_, let productID, let variationID, let onCompletion) = variationAction else { return }
            let variation = makeVariation(id: variationID, parentID: productID)
            storageManager.insertSampleProductVariation(readOnlyProductVariation: variation)
            onCompletion(.success(variation))
        })
        let refs = [makeVariationRef(10, parent: 1), makeVariationRef(11, parent: 1)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

        // Then
        #expect(dispatched.count == 2)
        #expect(isResolvedVariation(outcomes[refs[0]], id: 10, parentID: 1))
        #expect(isResolvedVariation(outcomes[refs[1]], id: 11, parentID: 1))
    }

    @Test
    func test_fetch_when_mixed_then_remote_called_only_for_misses() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProductVariation(readOnlyProductVariation: makeVariation(id: 5, parentID: 1))
        let dispatched = DispatchedVariationActions()
        let dataSource = AssistantProductVariationsDataSource(siteID: variationTestSiteID,
                                             storageManager: storageManager,
                                             dispatchAction: { action in
            dispatched.append(action)
            guard let variationAction = action as? ProductVariationAction,
                  case .retrieveProductVariation(_, let productID, let variationID, let onCompletion) = variationAction else { return }
            let variation = makeVariation(id: variationID, parentID: productID)
            storageManager.insertSampleProductVariation(readOnlyProductVariation: variation)
            onCompletion(.success(variation))
        })
        let refs = [makeVariationRef(5, parent: 1), makeVariationRef(6, parent: 1)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

        // Then
        #expect(dispatched.count == 1)
        #expect(isResolvedVariation(outcomes[refs[0]], id: 5, parentID: 1))
        #expect(isResolvedVariation(outcomes[refs[1]], id: 6, parentID: 1))
    }

    @Test
    func test_fetch_when_remote_fails_then_storage_hits_still_resolve() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProductVariation(readOnlyProductVariation: makeVariation(id: 5, parentID: 1))
        let dataSource = AssistantProductVariationsDataSource(siteID: variationTestSiteID,
                                             storageManager: storageManager,
                                             dispatchAction: { action in
            guard let variationAction = action as? ProductVariationAction,
                  case .retrieveProductVariation(_, _, _, let onCompletion) = variationAction else { return }
            onCompletion(.failure(SampleError.boom))
        })
        let refs = [makeVariationRef(5, parent: 1), makeVariationRef(99, parent: 1)]

        // When
        let outcomes = await dataSource.fetch(refs: refs)

        // Then
        #expect(isResolvedVariation(outcomes[refs[0]], id: 5, parentID: 1))
        #expect(isRejected(outcomes[refs[1]], reason: .fetchFailed))
    }

    @Test
    func test_fetch_when_action_succeeds_but_storage_still_empty_then_remote_result_resolves() async {
        // Given
        let storageManager = MockStorageManager()
        let dataSource = AssistantProductVariationsDataSource(siteID: variationTestSiteID,
                                             storageManager: storageManager,
                                             dispatchAction: { action in
            guard let variationAction = action as? ProductVariationAction,
                  case .retrieveProductVariation(_, let productID, let variationID, let onCompletion) = variationAction else { return }
            onCompletion(.success(makeVariation(id: variationID, parentID: productID)))
        })
        let ref = makeVariationRef(5, parent: 1)

        // When
        let outcomes = await dataSource.fetch(refs: [ref])

        // Then
        #expect(isResolvedVariation(outcomes[ref], id: 5, parentID: 1))
    }

    @Test
    func test_fetch_when_storage_entry_is_trash_then_rejected_as_staleReference() async {
        // Given
        let storageManager = MockStorageManager()
        let trashed = makeVariation(id: 5, parentID: 1).copy(status: .trash)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: trashed)
        let dataSource = AssistantProductVariationsDataSource(siteID: variationTestSiteID,
                                             storageManager: storageManager,
                                             dispatchAction: { _ in })

        // When
        let outcomes = await dataSource.fetch(refs: [makeVariationRef(5, parent: 1)])

        // Then
        #expect(isRejected(outcomes[makeVariationRef(5, parent: 1)], reason: .staleReference))
    }

    @Test
    func test_variationDisplayName_when_attributes_present_then_joins_options_with_comma() {
        // Given
        let attributes = [
            ProductVariationAttribute(id: 1, name: "Color", option: "Black"),
            ProductVariationAttribute(id: 2, name: "Size", option: "Large")
        ]

        // When
        let name = CardEntityPayloadFactory.payload(from: makeVariation(id: 5, parentID: 1).copy(attributes: attributes)).name

        // Then
        #expect(name == "Black, Large")
    }

    @Test
    func test_variationDisplayName_when_attributes_empty_then_returns_nil() {
        // Given
        let attributes: [ProductVariationAttribute] = []

        // When
        let name = CardEntityPayloadFactory.payload(from: makeVariation(id: 5, parentID: 1).copy(attributes: attributes)).name

        // Then
        #expect(name == nil)
    }

    @Test
    func test_variationDisplayName_when_some_options_blank_then_filters_them_out() {
        // Given
        let attributes = [
            ProductVariationAttribute(id: 1, name: "Color", option: "Black"),
            ProductVariationAttribute(id: 2, name: "Size", option: "")
        ]

        // When
        let name = CardEntityPayloadFactory.payload(from: makeVariation(id: 5, parentID: 1).copy(attributes: attributes)).name

        // Then
        #expect(name == "Black")
    }

    @Test
    func test_fetch_when_variation_has_no_parent_id_then_injected_from_request() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProductVariation(readOnlyProductVariation: makeVariation(id: 5, parentID: 42))
        let dataSource = AssistantProductVariationsDataSource(siteID: variationTestSiteID,
                                             storageManager: storageManager,
                                             dispatchAction: { _ in })
        let ref = makeVariationRef(5, parent: 42)

        // When
        let outcomes = await dataSource.fetch(refs: [ref])

        // Then
        guard case .found(.variation(let payload)) = outcomes[ref] else {
            Issue.record("expected variation")
            return
        }
        #expect(payload.parentID == 42)
    }

    @Test
    func test_fetch_when_cached_variation_parent_mismatches_request_then_refetches() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProductVariation(readOnlyProductVariation: makeVariation(id: 5, parentID: 99))
        let dataSource = AssistantProductVariationsDataSource(siteID: variationTestSiteID,
                                                              storageManager: storageManager,
                                                              dispatchAction: { action in
            guard let variationAction = action as? ProductVariationAction,
                  case .retrieveProductVariation(_, let productID, let variationID, let onCompletion) = variationAction else { return }
            onCompletion(.success(makeVariation(id: variationID, parentID: productID)))
        })
        let ref = makeVariationRef(5, parent: 42)

        // When
        let outcomes = await dataSource.fetch(refs: [ref])

        // Then
        #expect(isResolvedVariation(outcomes[ref], id: 5, parentID: 42))
    }

    @Test
    func test_updateVariation_when_called_then_updates_selected_fields() async throws {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProductVariation(readOnlyProductVariation: makeVariation(id: 5, parentID: 1).copy(sku: "CACHED-SKU"))
        var updatedFields: ProductVariationUpdateFields?
        let dataSource = AssistantProductVariationsDataSource(siteID: variationTestSiteID,
                                                              storageManager: storageManager,
                                                              dispatchAction: { action in
            guard let variationAction = action as? ProductVariationAction else { return }
            switch variationAction {
            case .updateProductVariationFields(_, let productID, let variationID, let fields, let onCompletion):
                updatedFields = fields
                onCompletion(.success(makeVariation(id: variationID, parentID: productID).copy(stockQuantity: Decimal(fields.stockQuantity ?? 0))))
            default:
                break
            }
        })

        // When
        let result = await dataSource.updateVariation(productID: 1,
                                                      variationID: 5,
                                                      patch: ProductVariationUpdatePatch(regularPrice: nil,
                                                                                         salePrice: nil,
                                                                                         stockQuantity: 4,
                                                                                         stockStatus: nil,
                                                                                         sku: nil,
                                                                                         status: nil))

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(updatedFields?.stockQuantity == 4)
    }
}

private func makeVariation(id: Int64, parentID: Int64) -> ProductVariation {
    ProductVariation.fake().copy(siteID: variationTestSiteID,
                                 productID: parentID,
                                 productVariationID: id,
                                 status: .published,
                                 sku: "VAR-\(id)",
                                 price: "9.99",
                                 stockStatus: .inStock)
}

private func makeVariationRef(_ id: Int64, parent: Int64) -> CardRef {
    CardRef(family: .productVariation, id: id, parentID: parent)
}

private func isResolvedVariation(_ outcome: CardEntityOutcome?, id: Int64, parentID: Int64) -> Bool {
    guard case .found(.variation(let payload)) = outcome else { return false }
    return payload.id == id && payload.parentID == parentID
}

private func isRejected(_ outcome: CardEntityOutcome?, reason: CardRefRejectionReason) -> Bool {
    guard case .rejected(let actual) = outcome else { return false }
    return actual == reason
}

@MainActor
private final class DispatchedVariationActions {
    private(set) var actions: [Action] = []

    var count: Int { actions.count }

    func append(_ action: Action) { actions.append(action) }
}

private enum SampleError: Error { case boom }
