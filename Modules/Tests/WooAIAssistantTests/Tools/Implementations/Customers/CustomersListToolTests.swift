import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
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

    @Test
    func test_summary_when_customer_has_username_then_username_is_projected() async throws {
        // Given
        let body = """
        [{"id": 1, "username": "povilas"}]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = CustomersListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        let first = try firstMatch(in: result)
        #expect(first["username"] == .string("povilas"))
    }

    @Test
    func test_summary_when_customer_has_date_created_then_date_created_is_projected() async throws {
        // Given
        let body = #"[{"id": 1, "date_created": "2026-04-20T10:00:00"}]"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = CustomersListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        let first = try firstMatch(in: result)
        #expect(first["date_created"] == .string("2026-04-20T10:00:00"))
    }

    @Test
    func test_summary_when_customer_has_billing_phone_city_country_then_billing_object_is_projected() async throws {
        // Given
        let body = """
        [{
            "id": 1,
            "billing": {"phone": "+1", "city": "Berlin", "country": "DE", "first_name": "X"}
        }]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = CustomersListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        let first = try firstMatch(in: result)
        guard case .object(let billing) = first["billing"] else {
            Issue.record("expected billing object")
            return
        }
        #expect(billing["phone"] == .string("+1"))
        #expect(billing["city"] == .string("Berlin"))
        #expect(billing["country"] == .string("DE"))
        #expect(billing["first_name"] == nil)
    }

    @Test
    func test_summary_when_customer_has_shipping_city_country_then_shipping_object_is_projected() async throws {
        // Given
        let body = """
        [{"id": 1, "shipping": {"city": "Berlin", "country": "DE", "phone": "+1"}}]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = CustomersListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        let first = try firstMatch(in: result)
        guard case .object(let shipping) = first["shipping"] else {
            Issue.record("expected shipping object")
            return
        }
        #expect(shipping["city"] == .string("Berlin"))
        #expect(shipping["country"] == .string("DE"))
        #expect(shipping["phone"] == nil)
    }

    @Test
    func test_summary_when_customer_has_role_and_avatar_then_both_are_projected() async throws {
        // Given
        let body = #"[{"id": 1, "role": "customer", "avatar_url": "https://example.com/a.jpg"}]"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = CustomersListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        let first = try firstMatch(in: result)
        #expect(first["role"] == .string("customer"))
        #expect(first["avatar_url"] == .string("https://example.com/a.jpg"))
    }

    @Test
    func test_summary_when_customer_has_blank_username_then_username_field_is_omitted() async throws {
        // Given
        let body = #"[{"id": 1, "username": ""}]"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = CustomersListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        let first = try firstMatch(in: result)
        #expect(first["username"] == nil)
    }

    @Test
    func test_summary_when_customer_present_then_orders_count_and_total_spent_are_not_projected() async throws {
        // Given
        let body = #"[{"id": 1, "orders_count": 4, "total_spent": "120.00"}]"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = CustomersListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        let first = try firstMatch(in: result)
        #expect(first["orders_count"] == nil)
        #expect(first["total_spent"] == nil)
    }

    private func firstMatch(in result: ToolResult) throws -> [String: AnyCodableJSON] {
        guard case .success(let success) = result,
              case .object(let fields) = success.structured,
              case .array(let matches) = fields["matches"],
              case .object(let first) = matches.first else {
            Issue.record("expected first match")
            throw FirstMatchError.missing
        }
        return first
    }

    private enum FirstMatchError: Error { case missing }
}
