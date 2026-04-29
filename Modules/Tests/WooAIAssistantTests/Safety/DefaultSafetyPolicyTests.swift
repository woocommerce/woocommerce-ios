import Foundation
import Testing
@testable import WooAIAssistant

struct DefaultSafetyPolicyTests {
    @Test
    func test_decision_when_tool_safe_then_execute() {
        // Given
        let tool = AITool(name: "orders_list",
                          description: "List orders",
                          parametersSchema: .object([:]),
                          safetyLevel: .safe)
        let policy = DefaultSafetyPolicy()

        // When
        let decision = policy.decision(for: tool.name, arguments: "{}", tool: tool)

        // Then
        #expect(decision == .execute)
    }

    @Test
    func test_decision_when_tool_unsafe_then_requireConfirmation_with_preview() {
        // Given
        let tool = AITool(name: "orders_update",
                          description: "Update an order",
                          parametersSchema: .object([:]),
                          safetyLevel: .unsafe)
        let policy = DefaultSafetyPolicy()

        // When
        let decision = policy.decision(for: tool.name,
                                       arguments: #"{"id":42,"status":"processing"}"#,
                                       tool: tool)

        // Then
        guard case .requireConfirmation(let preview) = decision else {
            Issue.record("expected .requireConfirmation, got \(decision)")
            return
        }
        #expect(preview.isEmpty == false)
        #expect(preview.contains("42"))
    }
}
