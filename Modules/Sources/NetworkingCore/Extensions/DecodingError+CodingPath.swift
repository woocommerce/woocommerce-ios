import Foundation

public extension DecodingError {
    private var context: Context {
        switch self {
        case .dataCorrupted(let context), .keyNotFound(_, let context), .typeMismatch(_, let context), .valueNotFound(_, let context):
            return context
        @unknown default:
            assertionFailure("⛔️ Unhandled Decoding Error: \(self)")
            return Context(codingPath: [], debugDescription: "")
        }
    }

    /// The path of coding keys taken to get to the point of the failing decode call, simplified.
    ///
    /// Outputs: `data.line_items.name`
    var debugPath: String {
        context.codingPath.map { $0.stringValue }.filter { !$0.hasPrefix("Index") }.joined(separator: ".")
    }

    /// A description of what went wrong, for debugging purposes.
    ///
    /// Outputs: `Expected to decode a Number but found a String instead`
    var debugDescription: String {
        context.debugDescription
    }
}
