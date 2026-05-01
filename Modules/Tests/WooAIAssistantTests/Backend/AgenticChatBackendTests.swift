import Foundation
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
                                  context: defaultContext,
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
                                  context: defaultContext,
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
                                   context: defaultContext,
                                   session: nil)
        for try await _ in stream1 {}
        let stream2 = backend.send(turn: .init(prompt: "second"),
                                   context: defaultContext,
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
                                  context: defaultContext,
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
                                      context: defaultContext,
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
    func test_send_when_turn_fails_mid_stream_then_transcript_not_polluted() async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.textDelta("first ok"), .completed(.stop)],
            [.textDelta("partial")],
            [.textDelta("third"), .completed(.stop)]
        ])
        let backend = AgenticChatBackend(chatService: chat, systemPrompt: nil)

        // When
        let stream1 = backend.send(turn: .init(prompt: "t1"),
                                   context: defaultContext,
                                   session: nil)
        for try await _ in stream1 {}
        await chat.setStreamError(AssistantError(kind: .upstreamFailure, message: "boom"))
        let stream2 = backend.send(turn: .init(prompt: "t2"),
                                   context: defaultContext,
                                   session: nil)
        for try await _ in stream2 {}
        await chat.setStreamError(nil)
        let stream3 = backend.send(turn: .init(prompt: "t3"),
                                   context: defaultContext,
                                   session: nil)
        for try await _ in stream3 {}

        // Then
        let captured = await chat.capturedRequests
        let messagesOnTurn3 = captured.last?.messages ?? []
        let userPrompts = messagesOnTurn3.filter { $0.role == .user }.compactMap { $0.content }
        #expect(userPrompts == ["t1", "t3"])
        let assistantTexts = messagesOnTurn3
            .filter { $0.role == .assistant && $0.content != nil }
            .compactMap { $0.content }
        #expect(assistantTexts == ["first ok"])
    }

    @Test
    func test_send_when_tool_calls_complete_in_reverse_order_then_transcript_replays_in_call_order()
    async throws {
        // Given
        let firstCall = OpenAIChat.ToolCall(
            id: "call_a",
            function: .init(name: "tool_a", arguments: "{}")
        )
        let secondCall = OpenAIChat.ToolCall(
            id: "call_b",
            function: .init(name: "tool_b", arguments: "{}")
        )
        let resultsCompletedInReverseOrder: [(String, String)] = [
            ("call_b", #"{"b":2}"#),
            ("call_a", #"{"a":1}"#)
        ]

        // When
        let (orderedCalls, orderedResults) = AgenticChatBackend.matchedPairs(
            toolCalls: [firstCall, secondCall],
            toolResults: resultsCompletedInReverseOrder
        )

        // Then
        #expect(orderedCalls.map(\.id) == ["call_a", "call_b"])
        #expect(orderedResults.map(\.0) == ["call_a", "call_b"])
        #expect(orderedResults.map(\.1) == [#"{"a":1}"#, #"{"b":2}"#])
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
        let backend = AgenticChatBackend(chatService: chat,
                                         systemPromptProvider: { UUID().uuidString })

        // When
        let stream1 = backend.send(turn: .init(prompt: "one"),
                                   context: defaultContext,
                                   session: nil)
        for try await _ in stream1 {}
        let stream2 = backend.send(turn: .init(prompt: "two"),
                                   context: defaultContext,
                                   session: nil)
        for try await _ in stream2 {}

        // Then
        let captured = await chat.capturedRequests
        let firstSystem = captured[0].messages.first(where: { $0.role == .system })?.content
        let secondSystem = captured[1].messages.first(where: { $0.role == .system })?.content
        #expect(firstSystem != nil)
        #expect(secondSystem != nil)
        #expect(firstSystem != secondSystem)
    }

    @Test
    func test_send_when_outcomeUnknown_emitted_mid_turn_then_next_turn_replays_full_transcript()
    async throws {
        // Given
        let writeTool = AITool(name: "orders_update",
                               description: "Update an order",
                               parametersSchema: .object([:]),
                               safetyLevel: .safe)
        let chat = MockAIChatService()
        let toolCall = OpenAIChat.ToolCall(
            id: "call_u",
            function: .init(name: "orders_update", arguments: #"{"id":42}"#)
        )
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)],
            [.textDelta("started — couldn't confirm"), .completed(.stop)],
            [.textDelta("not sure"), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool])
        await registry.setResult(for: "orders_update",
                                 result: .failed(.init(toolName: "orders_update",
                                                       kind: .outcomeUnknown,
                                                       reason: "URL cancelled mid-write")))
        let backend = AgenticChatBackend(chatService: chat,
                                         toolRegistry: registry,
                                         systemPrompt: nil)

        // When
        let stream1 = backend.send(turn: .init(prompt: "update order 42 to processing"),
                                   context: defaultContext,
                                   session: nil)
        for try await _ in stream1 {}
        let stream2 = backend.send(turn: .init(prompt: "did it work?"),
                                   context: defaultContext,
                                   session: nil)
        for try await _ in stream2 {}

        // Then
        let captured = await chat.capturedRequests
        let turn2Messages = try #require(captured.last?.messages)
        let userPrompts = turn2Messages.filter { $0.role == .user }.compactMap { $0.content }
        #expect(userPrompts == ["update order 42 to processing", "did it work?"])
        let assistantToolCallIDs = turn2Messages
            .filter { $0.role == .assistant }
            .flatMap { $0.toolCalls ?? [] }
            .map(\.id)
        #expect(assistantToolCallIDs == ["call_u"])
        let toolMessages = turn2Messages.filter { $0.role == .tool }
        #expect(toolMessages.compactMap(\.toolCallID) == ["call_u"])
        let assistantTexts = turn2Messages
            .filter { $0.role == .assistant && $0.content != nil }
            .compactMap { $0.content }
        #expect(assistantTexts.contains("started — couldn't confirm"))
    }

    @Test
    func test_send_when_terminal_failure_after_outcomeUnknown_then_transcript_not_appended()
    async throws {
        // Given
        let writeTool = AITool(name: "orders_update",
                               description: "Update an order",
                               parametersSchema: .object([:]),
                               safetyLevel: .safe)
        let chat = MockAIChatService()
        let toolCall = OpenAIChat.ToolCall(
            id: "call_t",
            function: .init(name: "orders_update", arguments: #"{"id":1}"#)
        )
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool])
        await registry.setResult(for: "orders_update",
                                 result: .failed(.init(toolName: "orders_update",
                                                       kind: .outcomeUnknown,
                                                       reason: "transport drop")))
        let backend = AgenticChatBackend(chatService: chat,
                                         toolRegistry: registry,
                                         systemPrompt: nil)

        // When
        var firstTurnEvents: [AssistantEvent] = []
        let stream1 = backend.send(turn: .init(prompt: "first prompt"),
                                   context: defaultContext,
                                   session: nil)
        for try await yield in stream1 {
            if case .event(let event) = yield {
                firstTurnEvents.append(event)
            }
        }
        await chat.setScriptedTurns([
            [.textDelta("second"), .completed(.stop)]
        ])
        let stream2 = backend.send(turn: .init(prompt: "second prompt"),
                                   context: defaultContext,
                                   session: nil)
        for try await _ in stream2 {}

        // Then
        let failureKinds = firstTurnEvents.compactMap { event -> AssistantErrorKind? in
            if case .failed(let error) = event { return error.kind }
            return nil
        }
        #expect(failureKinds.contains(.outcomeUnknown))
        #expect(failureKinds.contains(where: { $0 != .outcomeUnknown }))
        let captured = await chat.capturedRequests
        let turn2Messages = try #require(captured.last?.messages)
        let userPrompts = turn2Messages.filter { $0.role == .user }.compactMap { $0.content }
        #expect(userPrompts == ["second prompt"])
    }

    private let defaultContext = AssistantContext(
        siteID: 1,
        siteURL: URL(string: "https://example.com")!,
        blogID: nil
    )
}
