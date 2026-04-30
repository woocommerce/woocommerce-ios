import Foundation
import os
import Testing
@testable import WooAIAssistant

struct AgenticChatBackendTests {

    @Test
    func test_send_when_orchestrator_emits_textChunk_then_yields_event_textChunk() async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.textDelta("Hello"), .textDelta(", merchant"), .completed(.stop)]
        ])
        let backend = AgenticChatBackend(chatService: chat,
                                         systemPrompt: nil)

        // When
        var events: [AssistantEvent] = []
        let stream = backend.send(turn: .init(prompt: "Hi"),
                                  context: Self.defaultContext,
                                  session: nil)
        for try await yield in stream {
            if case .event(let event) = yield {
                events.append(event)
            }
        }

        // Then
        #expect(events.contains(.textChunk("Hello")))
        #expect(events.contains(.textChunk(", merchant")))
        #expect(events.contains(.completed(routeConfidence: nil)))
    }

    @Test
    func test_send_when_orchestrator_emits_failed_then_yields_event_failed() async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setStreamError(AssistantError(kind: .upstreamFailure,
                                                 message: "stream blew up"))
        let backend = AgenticChatBackend(chatService: chat,
                                         systemPrompt: nil)

        // When
        var events: [AssistantEvent] = []
        let stream = backend.send(turn: .init(prompt: "Hi"),
                                  context: Self.defaultContext,
                                  session: nil)
        for try await yield in stream {
            if case .event(let event) = yield {
                events.append(event)
            }
        }

        // Then
        let failed = events.compactMap { event -> AssistantError? in
            if case .failed(let error) = event { return error }
            return nil
        }.first
        let error = try #require(failed)
        #expect(error.message == "stream blew up")
    }

    @Test
    func test_send_when_called_twice_then_secondTurn_sees_firstTurn_transcript() async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.textDelta("Done."), .completed(.stop)],
            [.textDelta("OK."), .completed(.stop)]
        ])
        let backend = AgenticChatBackend(chatService: chat, systemPrompt: nil)

        // When
        let stream1 = backend.send(turn: .init(prompt: "first"),
                                   context: Self.defaultContext,
                                   session: nil)
        for try await _ in stream1 {}
        let stream2 = backend.send(turn: .init(prompt: "second"),
                                   context: Self.defaultContext,
                                   session: nil)
        for try await _ in stream2 {}

        // Then
        let captured = await chat.capturedRequests
        #expect(captured.count == 2)
        let secondMessages = captured[1].messages
        let userPrompts = secondMessages.filter { $0.role == .user }.compactMap { $0.content }
        #expect(userPrompts == ["first", "second"])
        let assistantTexts = secondMessages.filter { $0.role == .assistant }.compactMap { $0.content }
        #expect(assistantTexts.contains("Done."))
    }

    @Test
    func test_confirmProposal_when_called_then_resumes_orchestrator_with_true() async throws {
        // Given
        let unsafeTool = AITool(name: "orders_update",
                                description: "Update an order",
                                parametersSchema: .object([:]),
                                safetyLevel: .unsafe)
        let chat = MockAIChatService()
        let toolCall = OpenAIChat.ToolCall(
            id: "call_x",
            function: .init(name: "orders_update", arguments: #"{"id":1}"#)
        )
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([unsafeTool])
        await registry.setResult(for: "orders_update",
                                 result: .success(.init(toolName: "orders_update",
                                                        structured: .object(["id": .int(1)]))))
        let backend = AgenticChatBackend(chatService: chat,
                                         toolRegistry: registry,
                                         safetyPolicy: DefaultSafetyPolicy(),
                                         systemPrompt: nil)

        // When
        let stream = backend.send(turn: .init(prompt: "update order 1"),
                                  context: Self.defaultContext,
                                  session: nil)
        var events: [AssistantEvent] = []
        for try await yield in stream {
            if case .event(let event) = yield {
                events.append(event)
                if case .confirmationRequired(let proposal) = event {
                    await backend.confirmProposal(proposal.id)
                }
            }
        }

        // Then
        let resolved = events.compactMap { event -> Bool? in
            if case .confirmationResolved(_, let approved) = event { return approved }
            return nil
        }.first
        #expect(resolved == true)
        let invocations = await registry.invocationCount(for: "orders_update")
        #expect(invocations == 1)
    }

    @Test
    func test_transcript_when_toolCallStarted_without_completed_then_orphan_dropped_in_next_turn()
    async throws {
        // Given
        let started = OpenAIChat.ToolCall(
            id: "started_only",
            function: .init(name: "orders_list", arguments: "{}")
        )
        let paired = OpenAIChat.ToolCall(
            id: "paired",
            function: .init(name: "orders_list", arguments: "{}")
        )

        // When
        let (calls, results) = AgenticChatBackend.matchedPairs(
            toolCalls: [started, paired],
            toolResults: [("paired", "{}")]
        )

        // Then
        #expect(calls.map(\.id) == ["paired"])
        #expect(results.map(\.0) == ["paired"])
    }

    @Test
    func test_send_when_third_turn_after_two_with_tool_calls_then_replays_in_correct_wire_order()
    async throws {
        // Given
        let tool = AITool(name: "orders_list",
                          description: "List orders",
                          parametersSchema: .object([:]),
                          safetyLevel: .safe)
        let chat = MockAIChatService()
        let firstCall = OpenAIChat.ToolCall(id: "c1",
                                            function: .init(name: "orders_list",
                                                            arguments: "{}"))
        let secondCall = OpenAIChat.ToolCall(id: "c2",
                                             function: .init(name: "orders_list",
                                                             arguments: #"{"page":2}"#))
        await chat.setScriptedTurns([
            [.toolCall(firstCall), .completed(.toolCalls)],
            [.textDelta("ok 1"), .completed(.stop)],
            [.toolCall(secondCall), .completed(.toolCalls)],
            [.textDelta("ok 2"), .completed(.stop)],
            [.textDelta("done"), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([tool])
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(1)]))))
        let backend = AgenticChatBackend(chatService: chat,
                                         toolRegistry: registry,
                                         systemPrompt: nil)

        // When
        for prompt in ["t1", "t2", "t3"] {
            let stream = backend.send(turn: .init(prompt: prompt),
                                      context: Self.defaultContext,
                                      session: nil)
            for try await _ in stream {}
        }

        // Then
        let captured = await chat.capturedRequests
        let messagesOnTurn3 = captured.last?.messages ?? []
        let roles = messagesOnTurn3.map(\.role)
        #expect(roles == [.user, .assistant, .tool, .assistant,
                          .user, .assistant, .tool, .assistant,
                          .user])
        let userPrompts = messagesOnTurn3.filter { $0.role == .user }.compactMap { $0.content }
        #expect(userPrompts == ["t1", "t2", "t3"])
        let assistantTextPair = messagesOnTurn3
            .filter { $0.role == .assistant && $0.content != nil }
            .compactMap { $0.content }
        #expect(assistantTextPair == ["ok 1", "ok 2"])
        let toolCallIDs = messagesOnTurn3
            .filter { $0.role == .assistant }
            .flatMap { $0.toolCalls ?? [] }
            .map(\.id)
        #expect(toolCallIDs == ["c1", "c2"])
        let toolMessages = messagesOnTurn3.filter { $0.role == .tool }
        #expect(toolMessages.compactMap(\.toolCallID) == ["c1", "c2"])
    }

    @Test
    func test_systemPromptProvider_when_invoked_per_turn_then_rebuilt_each_call()
    async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.textDelta("a"), .completed(.stop)],
            [.textDelta("b"), .completed(.stop)]
        ])
        let counter = ProviderCallCounter()
        let backend = AgenticChatBackend(chatService: chat,
                                         systemPromptProvider: {
                                             "prompt-\(counter.bumpAndGet())"
                                         })

        // When
        let stream1 = backend.send(turn: .init(prompt: "one"),
                                   context: Self.defaultContext,
                                   session: nil)
        for try await _ in stream1 {}
        let stream2 = backend.send(turn: .init(prompt: "two"),
                                   context: Self.defaultContext,
                                   session: nil)
        for try await _ in stream2 {}

        // Then
        #expect(counter.snapshot() == 2)
        let captured = await chat.capturedRequests
        let firstSystem = captured[0].messages.first(where: { $0.role == .system })?.content
        let secondSystem = captured[1].messages.first(where: { $0.role == .system })?.content
        #expect(firstSystem == "prompt-1")
        #expect(secondSystem == "prompt-2")
    }

    private static let defaultContext = AssistantContext(
        siteID: 1,
        siteURL: URL(string: "https://example.com")!,
        blogID: nil
    )
}

/// Sendable counter without `@unchecked`.
private final class ProviderCallCounter: Sendable {
    private let lock = OSAllocatedUnfairLock(initialState: 0)

    func bumpAndGet() -> Int {
        lock.withLock { state in
            state += 1
            return state
        }
    }

    func snapshot() -> Int {
        lock.withLock { $0 }
    }
}
