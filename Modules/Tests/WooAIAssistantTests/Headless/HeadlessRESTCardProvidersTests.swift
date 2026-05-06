import Foundation
import Testing
@testable import WooAIAssistant

struct RESTOrderCardProviderTests {

    @Test
    func test_RESTOrderProvider_when_response_decodes_then_resolved_with_typed_entity() async {
        // Given
        let body = """
        [{"id": 3551, "number": "3551", "status": "processing", "total": "120.00",
          "currency": "USD", "date_created": "2024-01-02T03:04:05",
          "billing": {"first_name": "Jane", "last_name": "Doe", "email": "jane@example.com"}}]
        """
        let client = SyncStubWCRESTClient(response: WCRESTResponse(data: Data(body.utf8), statusCode: 200))
        let provider = RESTOrderCardProvider(client: client)
        let ref = CardRef(family: .order, id: 3551, parentID: 0)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .found(.order(let payload)) = outcomes[ref] else {
            Issue.record("expected order")
            return
        }
        #expect(payload.id == 3551)
        #expect(payload.customerName == "Jane Doe")
        #expect(payload.customerEmail == "jane@example.com")
    }

    @Test
    func test_RESTOrderProvider_when_status_is_trash_then_rejected_as_staleReference() async {
        // Given
        let body = #"[{"id": 1, "status": "trash"}]"#
        let client = SyncStubWCRESTClient(response: WCRESTResponse(data: Data(body.utf8), statusCode: 200))
        let provider = RESTOrderCardProvider(client: client)
        let ref = CardRef(family: .order, id: 1, parentID: 0)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .rejected(let reason) = outcomes[ref] else {
            Issue.record("expected rejection")
            return
        }
        #expect(reason == .staleReference)
    }

    @Test
    func test_RESTOrderProvider_when_status_404_then_rejected_as_notFound() async {
        // Given
        let client = SyncStubWCRESTClient(response: WCRESTResponse(data: Data(), statusCode: 404))
        let provider = RESTOrderCardProvider(client: client)
        let ref = CardRef(family: .order, id: 1, parentID: 0)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .rejected(let reason) = outcomes[ref] else {
            Issue.record("expected rejection")
            return
        }
        #expect(reason == .notFound)
    }
}

struct RESTProductCardProviderTests {

    @Test
    func test_RESTProductProvider_when_response_decodes_then_resolved_with_typed_entity() async {
        // Given
        let body = """
        [{"id": 42, "name": "Beanie", "sku": "BEAN-1", "price": "19.99",
          "stock_status": "instock", "status": "publish"}]
        """
        let client = SyncStubWCRESTClient(response: WCRESTResponse(data: Data(body.utf8), statusCode: 200))
        let provider = RESTProductCardProvider(client: client)
        let ref = CardRef(family: .product, id: 42, parentID: 0)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .found(.product(let payload)) = outcomes[ref] else {
            Issue.record("expected product")
            return
        }
        #expect(payload.id == 42)
        #expect(payload.name == "Beanie")
        #expect(payload.sku == "BEAN-1")
    }

    @Test
    func test_RESTProductProvider_when_status_is_trash_then_rejected_as_staleReference() async {
        // Given
        let body = #"[{"id": 1, "status": "trash"}]"#
        let client = SyncStubWCRESTClient(response: WCRESTResponse(data: Data(body.utf8), statusCode: 200))
        let provider = RESTProductCardProvider(client: client)
        let ref = CardRef(family: .product, id: 1, parentID: 0)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .rejected(let reason) = outcomes[ref] else {
            Issue.record("expected rejection")
            return
        }
        #expect(reason == .staleReference)
    }

    @Test
    func test_RESTProductProvider_when_status_404_then_rejected_as_notFound() async {
        // Given
        let client = SyncStubWCRESTClient(response: WCRESTResponse(data: Data(), statusCode: 404))
        let provider = RESTProductCardProvider(client: client)
        let ref = CardRef(family: .product, id: 1, parentID: 0)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .rejected(let reason) = outcomes[ref] else {
            Issue.record("expected rejection")
            return
        }
        #expect(reason == .notFound)
    }
}

struct RESTVariationCardProviderTests {

    // No trash test for variations: WC variations responses do not include a
    // top-level `status` field, and ProductVariationCardPayload omits status,
    // so trash filtering is not part of the REST contract for this family.

    @Test
    func test_RESTVariationProvider_when_response_decodes_then_resolved_with_parent_id_injected() async {
        // Given
        let body = """
        {"id": 99, "name": "Black, Large", "sku": "BEAN-BLK-L", "price": "19.99",
         "stock_status": "instock"}
        """
        let client = SyncStubWCRESTClient(response: WCRESTResponse(data: Data(body.utf8), statusCode: 200))
        let provider = RESTVariationCardProvider(client: client)
        let ref = CardRef(family: .productVariation, id: 99, parentID: 42)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .found(.variation(let payload)) = outcomes[ref] else {
            Issue.record("expected variation")
            return
        }
        #expect(payload.id == 99)
        #expect(payload.parentID == 42)
        #expect(payload.name == "Black, Large")
    }

    @Test
    func test_RESTVariationProvider_when_status_404_then_rejected_as_notFound() async {
        // Given
        let client = SyncStubWCRESTClient(response: WCRESTResponse(data: Data(), statusCode: 404))
        let provider = RESTVariationCardProvider(client: client)
        let ref = CardRef(family: .productVariation, id: 1, parentID: 2)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .rejected(let reason) = outcomes[ref] else {
            Issue.record("expected rejection")
            return
        }
        #expect(reason == .notFound)
    }
}
