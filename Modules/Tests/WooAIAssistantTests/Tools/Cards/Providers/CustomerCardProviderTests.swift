import Foundation
import Testing
@testable import WooAIAssistant

struct CustomerCardProviderTests {

    @Test
    func test_fetch_when_customer_in_REST_then_resolved() async {
        // Given
        let body = """
        [{"id": 7, "first_name": "Jane", "last_name": "Doe",
          "email": "jane@example.com", "username": "jdoe", "orders_count": 12}]
        """
        let client = SyncStubWCRESTClient(response: WCRESTResponse(data: Data(body.utf8), statusCode: 200))
        let provider = CustomerCardProvider(client: client)
        let ref = CardRef(family: .customer, id: 7, parentID: 0)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .found(.customer(let payload)) = outcomes[ref] else {
            Issue.record("expected customer")
            return
        }
        #expect(payload.id == 7)
        #expect(payload.firstName == "Jane")
        #expect(payload.email == "jane@example.com")
        #expect(payload.ordersCount == 12)
    }

    @Test
    func test_fetch_when_customer_REST_404_then_rejected_as_notFound() async {
        // Given
        let client = SyncStubWCRESTClient(response: WCRESTResponse(data: Data(), statusCode: 404))
        let provider = CustomerCardProvider(client: client)
        let ref = CardRef(family: .customer, id: 7, parentID: 0)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .rejected(let reason) = outcomes[ref] else {
            Issue.record("expected rejection")
            return
        }
        #expect(reason == .notFound)
    }

    @Test
    func test_fetch_when_id_missing_from_response_then_rejected_as_notFound() async {
        // Given
        let body = "[]"
        let client = SyncStubWCRESTClient(response: WCRESTResponse(data: Data(body.utf8), statusCode: 200))
        let provider = CustomerCardProvider(client: client)
        let ref = CardRef(family: .customer, id: 7, parentID: 0)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .rejected(let reason) = outcomes[ref] else {
            Issue.record("expected rejection")
            return
        }
        #expect(reason == .notFound)
    }

    @Test
    func test_fetch_when_REST_500_then_rejected_as_fetchFailed() async {
        // Given
        let client = SyncStubWCRESTClient(response: WCRESTResponse(data: Data(), statusCode: 500))
        let provider = CustomerCardProvider(client: client)
        let ref = CardRef(family: .customer, id: 7, parentID: 0)

        // When
        let outcomes = await provider.fetch(refs: [ref])

        // Then
        guard case .rejected(let reason) = outcomes[ref] else {
            Issue.record("expected rejection")
            return
        }
        #expect(reason == .fetchFailed)
    }
}
