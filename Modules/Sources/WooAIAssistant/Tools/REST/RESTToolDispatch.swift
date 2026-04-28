import Foundation

enum RESTToolDispatch {
    /// 1-50 keeps a hallucinated `per_page=500` from blowing the context window.
    static let perPageRange: ClosedRange<Int> = 1...50
    static let defaultPerPage: Int = 20

    static func clampedPerPage(_ value: Int?) -> Int {
        guard let value else { return defaultPerPage }
        return min(perPageRange.upperBound, max(perPageRange.lowerBound, value))
    }

    static func decodeArguments<T: Decodable>(_ type: T.Type,
                                              from json: String,
                                              toolName: String,
                                              toolCallID: String = "") -> Result<T, ToolResult.Failed> {
        guard let data = json.data(using: .utf8) else {
            return .failure(.init(toolName: toolName,
                                  toolCallID: toolCallID,
                                  kind: .invalidToolCall,
                                  reason: "argument string was not UTF-8"))
        }
        do {
            return .success(try JSONDecoder().decode(type, from: data))
        } catch {
            return .failure(.init(toolName: toolName,
                                  toolCallID: toolCallID,
                                  kind: .invalidToolCall,
                                  reason: error.localizedDescription))
        }
    }

    static func failed(from response: WCRESTResponse,
                       toolName: String,
                       toolCallID: String = "") -> ToolResult.Failed {
        let reason = String(data: response.data, encoding: .utf8).flatMap { $0.isEmpty ? nil : $0 }
            ?? "HTTP \(response.statusCode)"
        return .init(toolName: toolName,
                     toolCallID: toolCallID,
                     kind: HTTPStatusClassification.errorKind(forStatusCode: response.statusCode),
                     reason: reason,
                     code: String(response.statusCode))
    }
}
