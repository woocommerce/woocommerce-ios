import Foundation
import Testing
@testable import WooAIAssistant

struct RESTToolRegistryTests {
    @Test
    func test_execute_when_tool_unknown_then_returns_failed_invalidToolCall() async {
        // Given
        let registry = RESTToolRegistry(client: NoopWCRESTClient(), tools: [])

        // When
        let result = await registry.execute(name: "missing_tool", arguments: "{}", toolCallID: "call_xyz")

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected .failed, got \(result)")
            return
        }
        #expect(failed.toolName == "missing_tool")
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("missing_tool"))
        #expect(failed.toolCallID == "call_xyz")
    }

    @Test
    func test_execute_when_success_then_passes_payload_through() async {
        // Given
        let structured = AnyCodableJSON.object([
            "count": .int(2),
            "ids": .array([.int(3551), .int(3548)])
        ])
        let tool = RESTTool(
            definition: AITool(name: "orders_list",
                               description: "List orders",
                               parametersSchema: .object([:]),
                               safetyLevel: .safe),
            executor: { _, _ in
                .success(.init(toolName: "orders_list", structured: structured))
            }
        )
        let registry = RESTToolRegistry(client: NoopWCRESTClient(), tools: [tool])

        // When
        let result = await registry.execute(name: "orders_list", arguments: "{}")

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected .success, got \(result)")
            return
        }
        #expect(success.toolName == "orders_list")
        #expect(success.structured == structured)
        #expect(success.uiStructured == nil)
    }

    @Test
    func test_execute_stamps_toolCallID_overriding_what_executor_emits() async {
        // Given
        let tool = RESTTool(
            definition: AITool(name: "orders_get",
                               description: "Get",
                               parametersSchema: .object([:]),
                               safetyLevel: .safe),
            executor: { _, _ in
                .failed(.init(toolName: "orders_get",
                              toolCallID: "executor_emitted",
                              kind: .toolFailed,
                              reason: "stub"))
            }
        )
        let registry = RESTToolRegistry(client: NoopWCRESTClient(), tools: [tool])

        // When
        let result = await registry.execute(name: "orders_get", arguments: "{}", toolCallID: "call_real")

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected .failed, got \(result)")
            return
        }
        #expect(failed.toolCallID == "call_real")
    }

    @Test
    func test_execute_passes_arguments_and_client_to_executor() async {
        // Given
        let recorder = ExecutorRecorder()
        let probingClient = ProbingWCRESTClient()
        let tool = RESTTool(
            definition: AITool(name: "orders_get",
                               description: "Get one",
                               parametersSchema: .object([:]),
                               safetyLevel: .safe),
            executor: { arguments, client in
                await recorder.record(arguments: arguments)
                _ = await client.request(method: "GET",
                                         path: "wc/v3/orders/3551",
                                         query: nil,
                                         body: nil)
                return .success(.init(toolName: "orders_get", structured: .object(["ok": .bool(true)])))
            }
        )
        let registry = RESTToolRegistry(client: probingClient, tools: [tool])

        // When
        _ = await registry.execute(name: "orders_get", arguments: #"{"id":3551}"#)

        // Then
        #expect(await recorder.recordedArguments == #"{"id":3551}"#)
        #expect(await probingClient.callCount == 1)
        #expect(await probingClient.recordedPaths == ["wc/v3/orders/3551"])
    }

    @Test
    func test_availableTools_returns_registered_definitions() async throws {
        // Given
        let listTool = RESTTool(
            definition: AITool(name: "orders_list",
                               description: "List",
                               parametersSchema: .object([:]),
                               safetyLevel: .safe),
            executor: { _, _ in .failed(.init(toolName: "orders_list", kind: .toolFailed, reason: "stub")) }
        )
        let getTool = RESTTool(
            definition: AITool(name: "orders_get",
                               description: "Get",
                               parametersSchema: .object([:]),
                               safetyLevel: .safe),
            executor: { _, _ in .failed(.init(toolName: "orders_get", kind: .toolFailed, reason: "stub")) }
        )
        let registry = RESTToolRegistry(client: NoopWCRESTClient(), tools: [listTool, getTool])

        // When
        let definitions = try await registry.availableTools()

        // Then
        #expect(Set(definitions.map { $0.name }) == ["orders_list", "orders_get"])
    }

    @Test
    func test_availableTools_when_empty_then_returns_empty_array() async throws {
        // Given
        let registry = RESTToolRegistry(client: NoopWCRESTClient())

        // When
        let definitions = try await registry.availableTools()

        // Then
        #expect(definitions.isEmpty)
    }
}

// MARK: - Test doubles

private struct NoopWCRESTClient: WCRESTClient {
    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?) async -> WCRESTResponse {
        WCRESTResponse(data: Data(), statusCode: 200)
    }
}

private actor ExecutorRecorder {
    private(set) var recordedArguments: String?

    func record(arguments: String) {
        recordedArguments = arguments
    }
}

private actor ProbingWCRESTClient: WCRESTClient {
    private(set) var callCount = 0
    private(set) var recordedPaths: [String] = []

    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?) async -> WCRESTResponse {
        callCount += 1
        recordedPaths.append(path)
        return WCRESTResponse(data: Data(), statusCode: 200)
    }
}
