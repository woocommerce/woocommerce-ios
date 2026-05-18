import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct LoopDispatchOrderTests {

    @Test
    func test_dispatch_when_batch_mixes_write_and_read_then_write_runs_before_read() async throws {
        // Given
        let writeTool = AITool(name: "orders_update",
                               description: "Update an order",
                               parametersSchema: .object([:]),
                               safetyLevel: .unsafe)
        let readTool = AITool(name: "orders_get",
                              description: "Fetch an order",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let writeCall = OpenAIChat.ToolCall(
            id: "call_write",
            function: .init(name: "orders_update", arguments: #"{"id":42,"status":"processing"}"#)
        )
        let readCall = OpenAIChat.ToolCall(
            id: "call_read",
            function: .init(name: "orders_get", arguments: #"{"id":42}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(writeCall), .toolCall(readCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = OrderRecordingToolRegistry(availableTools: [writeTool, readTool])
        let safetyPolicy = AutoApprovingSafetyPolicy()
        let orchestrator = AgenticLoopOrchestrator(chatService: chat,
                                                   toolRegistry: registry,
                                                   safetyPolicy: safetyPolicy)

        // When
        for try await _ in orchestrator.run(prompt: "Update and re-fetch order 42") {}

        // Then
        let order = await registry.executionOrder
        #expect(order == ["orders_update", "orders_get"])
        let readSawWriteDone = await registry.writeDoneObservedAtReadStart
        #expect(readSawWriteDone == true)
    }
}

/// Records every execute() invocation in arrival order so tests can pin write-before-read
/// dispatch. Also exposes a flag the write flips on completion so reads can assert they
/// observed the post-write state.
private actor OrderRecordingToolRegistry: ToolRegistry {

    private(set) var executionOrder: [String] = []
    private(set) var writeDoneObservedAtReadStart: Bool?
    private var writeDone = false
    private let tools: [AITool]

    init(availableTools: [AITool]) {
        self.tools = availableTools
    }

    func availableTools() async throws -> [AITool] {
        tools
    }

    func execute(name: String, arguments: String, toolCallID: String) async -> ToolResult {
        executionOrder.append(name)
        if name == "orders_get" && writeDoneObservedAtReadStart == nil {
            writeDoneObservedAtReadStart = writeDone
        }
        let result = ToolResult.success(.init(toolName: name,
                                              structured: .object(["id": .int(42)])))
        if name == "orders_update" {
            writeDone = true
        }
        return result.stamping(toolCallID: toolCallID)
    }
}

/// Approves every confirmation so tests can focus on dispatch ordering rather than the
/// confirmation handshake.
private struct AutoApprovingSafetyPolicy: SafetyPolicy {
    func decision(for name: String,
                  arguments: String,
                  tool: AITool) async -> SafetyDecision {
        .execute
    }
}
