import Foundation

/// Sanitized context for a response that does not satisfy a login API operation.
public struct UnexpectedStoreResponseError: Error, Equatable, Sendable, CustomNSError, CustomStringConvertible, CustomDebugStringConvertible {
    public enum Kind: String, Sendable {
        case unexpectedContent = "unexpected_content"
        case unacceptableStatusCode = "unacceptable_status_code"
    }

    public struct Diagnostics: Equatable, Sendable {
        public let contentType: String?
        public let request: String
        public let excerpt: String?
    }

    public let kind: Kind
    public let statusCode: Int?
    public let diagnostics: Diagnostics?
    var isDecodingFailure = false

    public init(kind: Kind, statusCode: Int? = nil) {
        self.kind = kind
        self.statusCode = statusCode
        self.diagnostics = nil
    }

    init(kind: Kind, statusCode: Int?, data: Data? = nil, contentType: String?, request: URLRequest?) {
        self.kind = kind
        self.statusCode = statusCode
        self.diagnostics = Diagnostics(
            contentType: contentType?.split(separator: ";").first.map { UnexpectedResponseMetadata.sanitize(String($0).lowercased()) },
            request: UnexpectedResponseMetadata.sanitize("\(request?.httpMethod ?? "GET") \(request?.url?.path ?? "/")"),
            excerpt: data.flatMap { String(data: $0, encoding: .utf8) }.flatMap(UnexpectedResponseExcerpt.make)
        )
    }

    public var description: String { "Unexpected store response (\(kind.rawValue))." }
    public var debugDescription: String { description }
    public static var errorDomain: String { "UnexpectedStoreResponse" }
    public var errorCode: Int { statusCode ?? 0 }
    public var errorUserInfo: [String: Any] { [NSLocalizedDescriptionKey: description] }

    var logMessage: String {
        "Unexpected store response: kind=\(kind.rawValue), status=\(statusCode.map(String.init) ?? "unknown"), " +
        "content_type=\(diagnostics?.contentType ?? ""), request=\(diagnostics?.request ?? ""), excerpt=\(diagnostics?.excerpt ?? "")"
    }
}
