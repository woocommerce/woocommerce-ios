import Foundation
@testable import WooAIAssistant

actor MockToolRegistry: ToolRegistry {
    var availableToolsList: [AITool] = []
    var availableToolsError: Error?
    var resultsByToolName: [String: ToolResult] = [:]
    var resultsByToolCallID: [String: ToolResult] = [:]
    var defaultResult: ToolResult = .success(.init(toolName: "default", structured: .object([:])))

    private var invocationCountsByName: [String: Int] = [:]
    private var lastArgumentsByName: [String: String] = [:]

    func availableTools() async throws -> [AITool] {
        if let availableToolsError {
            throw availableToolsError
        }
        return availableToolsList
    }

    func execute(name: String, arguments: String, toolCallID: String) async -> ToolResult {
        invocationCountsByName[name, default: 0] += 1
        lastArgumentsByName[name] = arguments
        let result: ToolResult
        if let scripted = resultsByToolCallID[toolCallID] {
            result = scripted
        } else if let scripted = resultsByToolName[name] {
            result = scripted
        } else {
            result = defaultResult
        }
        return result.stamping(toolCallID: toolCallID)
    }

    func invocationCount(for toolName: String) -> Int {
        invocationCountsByName[toolName, default: 0]
    }

    func lastArguments(for toolName: String) -> String? {
        lastArgumentsByName[toolName]
    }

    func setAvailableTools(_ tools: [AITool]) {
        availableToolsList = tools
    }

    func setResult(for toolName: String, result: ToolResult) {
        resultsByToolName[toolName] = result
    }
}
