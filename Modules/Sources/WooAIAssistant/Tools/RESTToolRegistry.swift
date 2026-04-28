import Foundation

/// Unknown tool names short-circuit to `.failed(kind: .invalidToolCall)` so
/// callers never need a typo guard before dispatch.
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

public struct RESTTool: Sendable {
    public let definition: AITool
    public let executor: @Sendable (_ arguments: String, _ client: WCRESTClient) async -> ToolResult

    public init(definition: AITool,
                executor: @escaping @Sendable (_ arguments: String, _ client: WCRESTClient) async -> ToolResult) {
        self.definition = definition
        self.executor = executor
    }
}
