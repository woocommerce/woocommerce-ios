import Foundation
import Testing
@testable import WooAIAssistant

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
        #expect(preview.fields.first?.value == .raw("pending"))
    }
}
