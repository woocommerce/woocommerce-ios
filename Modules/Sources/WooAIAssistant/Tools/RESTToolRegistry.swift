import Foundation

/// Concrete `ToolRegistry` whose tools call into the merchant's WooCommerce
/// REST API through `WCRESTClient`. Constructable empty so the dispatch loop
/// works without any tools registered.
///
/// Unknown tool names short-circuit to `.failed(kind: .invalidToolCall)` so
/// the orchestrator never has to guard against typos before dispatch - one
/// classification path, one place errors live.
public struct RESTToolRegistry: ToolRegistry {
    private let client: WCRESTClient
    private let tools: [String: RESTTool]

    public init(client: WCRESTClient, tools: [RESTTool] = []) {
        self.client = client
        self.tools = Dictionary(uniqueKeysWithValues: tools.map { ($0.definition.name, $0) })
    }

    public func availableTools() async throws -> [AITool] {
        tools.values.map { $0.definition }
    }

    public func execute(name: String, arguments: String) async -> ToolResult {
        guard let tool = tools[name] else {
            return .failed(.init(toolName: name,
                                 toolCallID: "",
                                 kind: .invalidToolCall,
                                 reason: "Unknown tool: \(name)"))
        }
        return await tool.executor(arguments, client)
    }
}

/// Pairs an `AITool` schema with the `@Sendable` async executor that runs
/// when the model calls it. The executor returns a fully-formed `ToolResult`
/// rather than throwing so retry classification, safety rejections, and
/// confirmation flows live behind one return type.
public struct RESTTool: Sendable {
    public let definition: AITool
    public let executor: @Sendable (_ arguments: String, _ client: WCRESTClient) async -> ToolResult

    public init(definition: AITool,
                executor: @escaping @Sendable (_ arguments: String, _ client: WCRESTClient) async -> ToolResult) {
        self.definition = definition
        self.executor = executor
    }
}
