import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct DefaultSafetyPolicyTests {
    @Test
    func test_decision_when_tool_safe_then_execute() async {
        // Given
        let tool = AITool(name: "orders_list",
                          description: "List orders",
                          parametersSchema: .object([:]),
                          safetyLevel: .safe)
        let policy = DefaultSafetyPolicy()

        // When
        let decision = await policy.decision(for: tool.name, arguments: "{}", tool: tool)

        // Then
        #expect(decision == .execute)
    }

    @Test
    func test_decision_when_tool_unsafe_then_requireConfirmation_with_typed_preview() async {
        // Given
        let tool = AITool(name: "orders_update",
                          description: "Update an order",
                          parametersSchema: .object([:]),
                          safetyLevel: .unsafe)
        let policy = DefaultSafetyPolicy()

        // When
        let decision = await policy.decision(for: tool.name,
                                             arguments: #"{"id":42,"status":"pending"}"#,
                                             tool: tool)

        // Then
        guard case .requireConfirmation(let preview) = decision else {
            Issue.record("expected .requireConfirmation, got \(decision)")
            return
        }
        #expect(preview.fields.first?.name == "status")
        #expect(preview.fields.first?.value == .raw("Pending Payment"))
    }

    // The default-arg construction the production adaptor uses: real resolver + real builder, only the
    // REST transport is stubbed. Pins the end-to-end wiring path the merchant exercises in the chat surface.
    @Test
    func test_decision_when_tool_unsafe_with_resolver_then_priorValue_reaches_preview() async {
        // Given
        let tool = AITool(name: OrdersUpdateTool.name,
                          description: "Update an order",
                          parametersSchema: .object([:]),
                          safetyLevel: .unsafe)
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/orders/42",
                                 body: #"{"id":42,"status":"processing"}"#)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)
        let policy = DefaultSafetyPolicy(snapshotResolver: resolver)

        // When
        let decision = await policy.decision(for: tool.name,
                                             arguments: #"{"id":42,"status":"pending"}"#,
                                             tool: tool)

        // Then
        guard case .requireConfirmation(let preview) = decision else {
            Issue.record("expected .requireConfirmation, got \(decision)")
            return
        }
        let field = preview.fields.first { $0.name == "status" }
        #expect(field?.priorValue == .raw("Processing"))
    }
}

private actor StubRESTClient: WCRESTClient {

    private var responsesByPath: [String: WCRESTResponse] = [:]

    func setResponse(forPath path: String, body: String, statusCode: Int = 200) {
        responsesByPath[path] = WCRESTResponse(data: Data(body.utf8), statusCode: statusCode)
    }

    nonisolated func request(method: String,
                             path: String,
                             query: [String: String]?,
                             body: Data?) async -> WCRESTResponse {
        await response(forPath: path)
    }

    private func response(forPath path: String) -> WCRESTResponse {
        responsesByPath[path] ?? WCRESTResponse(data: Data(), statusCode: 0)
    }
}
