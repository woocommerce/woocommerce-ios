import Foundation

enum ToolArgumentValidation {
    static func validate(arguments: String,
                         allowed: Set<String>,
                         toolName: String) -> ToolResult.Failed? {
        guard let data = arguments.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data),
              let object = parsed as? [String: Any] else {
            return nil
        }
        return rejection(forKeys: object.keys, allowed: allowed, toolName: toolName)
    }

    static func validate(patch: AnyCodableJSON,
                         allowed: Set<String>,
                         toolName: String) -> ToolResult.Failed? {
        guard case .object(let dict) = patch else { return nil }
        return rejection(forKeys: dict.keys, allowed: allowed, toolName: toolName)
    }

    private static func rejection<Keys: Sequence>(forKeys keys: Keys,
                                                  allowed: Set<String>,
                                                  toolName: String) -> ToolResult.Failed?
    where Keys.Element == String {
        let unknown = keys.filter { !allowed.contains($0) }.sorted()
        guard !unknown.isEmpty else { return nil }
        let list = unknown.joined(separator: ", ")
        return .init(toolName: toolName,
                     kind: .invalidToolCall,
                     reason: "Unsupported \(toolName) argument(s): \(list)")
    }
}
