import Foundation
import Fakes
import Testing
import Yosemite
import YosemiteTestHelpers
@testable import WooAIAssistant

private let variationTestSiteID: Int64 = 123

@MainActor
struct VariationCardProviderTests {

    @Test
    func test_fetch_when_all_in_storage_then_no_remote_call() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProductVariation(readOnlyProductVariation: makeVariation(id: 5, parentID: 1))
        let dispatched = DispatchedVariationActions()
        let provider = VariationCardProvider(siteID: variationTestSiteID,
                                             storageManager: storageManager,
                                             dispatchAction: { dispatched.append($0) })
        let refs = [makeVariationRef(5, parent: 1)]

        // When
        let outcomes = await provider.fetch(refs: refs)

        // Then
        #expect(isResolvedVariation(outcomes[refs[0]], id: 5, parentID: 1))
        #expect(dispatched.actions.isEmpty)
    }

    @Test
    func test_fetch_when_none_in_storage_then_remote_called_for_all() async {
        // Given
        let storageManager = MockStorageManager()
        let dispatched = DispatchedVariationActions()
        let provider = VariationCardProvider(siteID: variationTestSiteID,
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
        let outcomes = await provider.fetch(refs: refs)

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
        let provider = VariationCardProvider(siteID: variationTestSiteID,
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
        let outcomes = await provider.fetch(refs: refs)

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
        let provider = VariationCardProvider(siteID: variationTestSiteID,
                                             storageManager: storageManager,
                                             dispatchAction: { action in
            guard let variationAction = action as? ProductVariationAction,
                  case .retrieveProductVariation(_, _, _, let onCompletion) = variationAction else { return }
            onCompletion(.failure(SampleError.boom))
        })
        let refs = [makeVariationRef(5, parent: 1), makeVariationRef(99, parent: 1)]

        // When
        let outcomes = await provider.fetch(refs: refs)

        // Then
        #expect(isResolvedVariation(outcomes[refs[0]], id: 5, parentID: 1))
        #expect(isRejected(outcomes[refs[1]], reason: .fetchFailed))
    }

    @Test
    func test_fetch_when_action_succeeds_but_storage_still_empty_then_rejected_as_notFound() async {
        // Given
        let storageManager = MockStorageManager()
        let provider = VariationCardProvider(siteID: variationTestSiteID,
                                             storageManager: storageManager,
                                             dispatchAction: { action in
            // Simulate the action succeeding without writing through to storage,
            // which is what happens when the server returns a 200 for an id
            // the upsert path does not persist.
            guard let variationAction = action as? ProductVariationAction,
                  case .retrieveProductVariation(_, let productID, let variationID, let onCompletion) = variationAction else { return }
            onCompletion(.success(makeVariation(id: variationID, parentID: productID)))
        })
        let ref = makeVariationRef(5, parent: 1)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        #expect(isRejected(outcomes[ref], reason: .notFound))
    }

    @Test
    func test_fetch_when_storage_entry_is_trash_then_rejected_as_staleReference() async {
        // Given
        let storageManager = MockStorageManager()
        let trashed = makeVariation(id: 5, parentID: 1).copy(status: .trash)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: trashed)
        let provider = VariationCardProvider(siteID: variationTestSiteID,
                                             storageManager: storageManager,
                                             dispatchAction: { _ in })

        // When
        let outcomes = await provider.fetch(refs: [makeVariationRef(5, parent: 1)])

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
        let name = variationDisplayName(from: attributes)

        // Then
        #expect(name == "Black, Large")
    }

    @Test
    func test_variationDisplayName_when_attributes_empty_then_returns_nil() {
        // Given
        let attributes: [ProductVariationAttribute] = []

        // When
        let name = variationDisplayName(from: attributes)

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
        let name = variationDisplayName(from: attributes)

        // Then
        #expect(name == "Black")
    }

    @Test
    func test_fetch_when_variation_has_no_parent_id_then_injected_from_request() async {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleProductVariation(readOnlyProductVariation: makeVariation(id: 5, parentID: 99))
        let provider = VariationCardProvider(siteID: variationTestSiteID,
                                             storageManager: storageManager,
                                             dispatchAction: { _ in })
        let ref = makeVariationRef(5, parent: 42)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .found(.variation(let payload)) = outcomes[ref] else {
            Issue.record("expected variation")
            return
        }
        #expect(payload.parentID == 42)
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

private final class DispatchedVariationActions: @unchecked Sendable {
    nonisolated(unsafe) private(set) var actions: [Action] = []

    var count: Int { actions.count }

    func append(_ action: Action) { actions.append(action) }
}

private enum SampleError: Error { case boom }
