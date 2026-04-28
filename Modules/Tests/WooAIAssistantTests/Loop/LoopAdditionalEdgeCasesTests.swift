import Foundation
import Testing
@testable import WooAIAssistant

struct LoopAdditionalEdgeCasesTests {

    @Test
    func test_run_when_tool_called_5_times_with_varying_args_then_5th_call_returns_per_tool_cap_envelope() async throws {
        // Given
        let listTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let chat = MockAIChatService()
        var scriptedTurns: [[ChatStreamEvent]] = (0..<5).map { i in
            let call = OpenAIChat.ToolCall(
                id: "call_\(i)",
                function: .init(name: "orders_list",
                                arguments: #"{"page":\#(i + 1)}"#)
            )
            return [.toolCall(call), .completed(.toolCalls)]
        }
        scriptedTurns.append([.textDelta("All done."), .completed(.stop)])
        await chat.setScriptedTurns(scriptedTurns)
        let registry = MockToolRegistry()
        await registry.setAvailableTools([listTool])
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(0)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat,
                                                   toolRegistry: registry,
                                                   maxIterations: 7)

        // When
        for try await _ in orchestrator.run(prompt: "List everything") {}

        // Then
        let invocations = await registry.invocationCount(for: "orders_list")
        #expect(invocations == 4)

        let capturedRequests = await chat.capturedRequests
        let capExceededFound = capturedRequests.contains { request in
            request.messages.contains { message in
                guard message.role == .tool, let content = message.content else { return false }
                return content.contains("per_tool_cap_exceeded")
            }
        }
        #expect(capExceededFound)
    }
}
