/// Single dispatch surface every executor implements. `execute` returns a typed `ToolResult`
/// rather than throwing, so error classification is part of the contract not a side effect.
public protocol ToolRegistry: Sendable {
    func availableTools() async throws -> [AITool]
    func execute(name: String, arguments: String) async -> ToolResult
}
