import Foundation
import Testing
@testable import WooAIAssistant

struct CardReferenceResolverTests {

    @Test
    func test_resolve_when_three_mixed_family_references_then_each_provider_handles_its_family() async {
        // Given
        let order = OrderCardPayload(id: 3551, number: "3551", status: "processing", total: "120.00")
        let product = ProductCardPayload(id: 42, name: "Beanie", sku: nil, price: "19.99")
        let customer = CustomerCardPayload(id: 7, firstName: "Jane")
        let providers: [CardFamily: any CardEntityProvider] = [
            .order: MockCardEntityProvider(found: [3551: .order(order)]),
            .product: MockCardEntityProvider(found: [42: .product(product)]),
            .customer: MockCardEntityProvider(found: [7: .customer(customer)])
        ]
        let resolver = CardReferenceResolver(providers: providers)
        let references = [
            CardReference(family: .order, id: "3551"),
            CardReference(family: .product, id: "42"),
            CardReference(family: .customer, id: "7")
        ]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(resolutions.count == 3)
        #expect(isResolved(resolutions[0], family: .order, id: "3551"))
        #expect(isResolved(resolutions[1], family: .product, id: "42"))
        #expect(isResolved(resolutions[2], family: .customer, id: "7"))
    }

    @Test
    func test_resolve_when_multiple_orders_then_provider_called_once_with_all_ids() async {
        // Given
        let mockProvider = MockCardEntityProvider(found: [
            1: .order(OrderCardPayload(id: 1)),
            2: .order(OrderCardPayload(id: 2)),
            3: .order(OrderCardPayload(id: 3))
        ])
        let resolver = CardReferenceResolver(providers: [.order: mockProvider])
        let references = [1, 2, 3].map { CardReference(family: .order, id: String($0)) }

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(resolutions.count == 3)
        let observedCalls = mockProvider.calls
        #expect(observedCalls.count == 1)
        #expect(observedCalls.first?.map { $0.id }.sorted() == [1, 2, 3])
    }

    @Test
    func test_resolve_when_eleven_references_then_first_ten_processed_and_overflow_rejected_as_overLimit() async {
        // Given
        let entities = (1...10).reduce(into: [Int64: CardEntity]()) { acc, id in
            acc[Int64(id)] = .order(OrderCardPayload(id: Int64(id)))
        }
        let resolver = CardReferenceResolver(providers: [.order: MockCardEntityProvider(found: entities)])
        let references = (1...11).map { CardReference(family: .order, id: String($0)) }

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(resolutions.count == 11)
        for index in 0..<10 {
            #expect(isResolved(resolutions[index], family: .order, id: String(index + 1)))
        }
        #expect(isRejected(resolutions[10], reason: .overLimit))
    }

    @Test
    func test_resolve_when_duplicate_id_within_family_then_second_rejected_as_duplicate() async {
        // Given
        let providers: [CardFamily: any CardEntityProvider] = [
            .order: MockCardEntityProvider(found: [1: .order(OrderCardPayload(id: 1))])
        ]
        let resolver = CardReferenceResolver(providers: providers)
        let references = [
            CardReference(family: .order, id: "1"),
            CardReference(family: .order, id: "1")
        ]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(isResolved(resolutions[0], family: .order, id: "1"))
        #expect(isRejected(resolutions[1], reason: .duplicate))
    }

    @Test
    func test_resolve_when_id_is_zero_or_negative_then_rejected_as_malformed() async {
        // Given
        let resolver = CardReferenceResolver(providers: [.order: MockCardEntityProvider(found: [:])])
        let references = [
            CardReference(family: .order, id: "0"),
            CardReference(family: .order, id: "-5"),
            CardReference(family: .order, id: "abc")
        ]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        for resolution in resolutions {
            #expect(isRejected(resolution, reason: .malformed))
        }
    }

    @Test
    func test_resolve_when_variation_missing_parent_id_then_rejected_as_malformed() async {
        // Given
        let resolver = CardReferenceResolver(providers: [.productVariation: MockCardEntityProvider(found: [:])])
        let references = [CardReference(family: .productVariation, id: "5")]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(isRejected(resolutions[0], reason: .malformed))
    }

    @Test
    func test_resolve_when_provider_returns_notFound_then_rejection_propagates() async {
        // Given
        let provider = MockCardEntityProvider(found: [:])
        let resolver = CardReferenceResolver(providers: [.order: provider])
        let references = [CardReference(family: .order, id: "999")]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(isRejected(resolutions[0], reason: .notFound))
    }

    @Test
    func test_resolve_when_no_provider_for_family_then_rejected_as_internalError() async {
        // Given
        let resolver = CardReferenceResolver(providers: [:])
        let references = [CardReference(family: .order, id: "1")]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(isRejected(resolutions[0], reason: .internalError))
    }
}

private final class MockCardEntityProvider: CardEntityProvider, @unchecked Sendable {
    nonisolated(unsafe) private(set) var calls: [[CardRef]] = []
    private let found: [Int64: CardEntity]

    init(found: [Int64: CardEntity]) {
        self.found = found
    }

    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome] {
        calls.append(refs)
        var outcomes: [CardRef: CardEntityOutcome] = [:]
        for ref in refs {
            if let entity = found[ref.id] {
                outcomes[ref] = .found(entity)
            } else {
                outcomes[ref] = .rejected(.notFound)
            }
        }
        return outcomes
    }
}

private func isResolved(_ resolution: Resolution, family: CardFamily, id: String) -> Bool {
    guard case .resolved(let actualFamily, let actualID, _) = resolution else { return false }
    return actualFamily == family && actualID == id
}

private func isRejected(_ resolution: Resolution, reason: CardRefRejectionReason) -> Bool {
    guard case .rejected(_, _, let actual) = resolution else { return false }
    return actual == reason
}
