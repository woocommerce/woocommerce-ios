import Foundation
import Testing
@testable import WooAIAssistant

struct CustomersListToolTests {
    @Test
    func test_customers_list_when_response_is_array_then_summary_carries_id_resolution_matches() async throws {
        // Given
        let body = """
        [
            {"id": 42, "first_name": "Povilas", "last_name": "Staskus", "email": "p@example.com"},
            {"id": 73, "first_name": "Pat", "last_name": "Jones", "email": "pat@example.com"}
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = CustomersListTool.make()

        // When
        let result = await tool.executor(#"{"search": "Pov"}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success")
            return
        }
        #expect(success.uiStructured == nil)
        if case .object(let fields) = success.structured {
            #expect(fields["count"] == .int(2))
            #expect(fields["ids"] == nil)
            if case .array(let matches) = fields["matches"], let first = matches.first, case .object(let firstDict) = first {
                #expect(firstDict["id"] == .int(42))
                #expect(firstDict["first_name"] == .string("Povilas"))
                #expect(firstDict["email"] == .string("p@example.com"))
            } else {
                Issue.record("expected first match object")
            }
        } else {
            Issue.record("expected object structured")
        }
        #expect(await client.calls.first?.query["search"] == "Pov")
    }

    @Test
    func test_customers_list_when_include_passed_then_query_carries_csv_ids() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = CustomersListTool.make()

        // When
        _ = await tool.executor(#"{"include": [42, 73]}"#, client)

        // Then
        #expect(await client.calls.first?.query["include"] == "42,73")
    }

    @Test
    func test_customers_list_when_response_is_401_then_returns_failed_with_auth_kind() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 401))
        let tool = CustomersListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .auth)
    }
}
