import Foundation

protocol JetpackTunnelRawBodyErrorLogging {
    func logIfNeeded(responseData: Data?, request: Request, transportStatus: Int?)
}

struct JetpackTunnelRawBodyErrorLogger: JetpackTunnelRawBodyErrorLogging {
    private typealias JSONDictionary = [String: Any]

    private let maxSnippetLength: Int
    private let warningSink: (String) -> Void

    init(maxSnippetLength: Int = 2048, warningSink: @escaping (String) -> Void = { DDLogWarn($0) }) {
        self.maxSnippetLength = maxSnippetLength
        self.warningSink = warningSink
    }

    func logIfNeeded(responseData: Data?, request: Request, transportStatus: Int?) {
        guard let responseData,
              let jetpackRequest = request as? JetpackRequest,
              let message = buildMessage(responseData: responseData, request: jetpackRequest, transportStatus: transportStatus) else {
            return
        }

        warningSink(message)
    }

    func buildMessage(responseData: Data, request: JetpackRequest, transportStatus: Int?) -> String? {
        guard let rawBodyError = rawBodyErrorContext(from: responseData) else {
            return nil
        }

        let snippet = sanitizedSnippet(rawBodyError.rawBody)
        return [
            "Jetpack Tunnel raw_body error:",
            "method=\(sanitize(request.method.rawValue.uppercased())),",
            "path=\(sanitize(normalizedPath(for: request))),",
            "transport_status=\(transportStatus.map { String($0) } ?? "nil"),",
            "proxy_status=\(rawBodyError.proxyStatus.map { String($0) } ?? "nil"),",
            "error_code=\(sanitize(rawBodyError.errorCode ?? "nil")),",
            "error_message=\(sanitize(rawBodyError.errorMessage ?? "nil")),",
            "raw_body_truncated=\(snippet.truncated),",
            "raw_body_snippet=\(snippet.value)"
        ].joined(separator: " ")
    }
}

private extension JetpackTunnelRawBodyErrorLogger {
    struct RawBodyErrorContext {
        let errorCode: String?
        let errorMessage: String?
        let proxyStatus: Int?
        let rawBody: String
    }

    struct RedactionPattern {
        let expression: String
        let replacement: String
    }

    private static let redactionPatterns: [RedactionPattern] = [
        RedactionPattern(
            expression: #"(?i)(authorization\s*[:=]\s*(?:[a-z]+\s+)?)[^\s<>,;"\\]+(?=\\[nrtvf]|\s|[<>,;"]|$)"#,
            replacement: "$1[redacted]"
        ),
        RedactionPattern(
            expression: #"(?i)\b((?:set-cookie|cookie)\s*[:=]\s*).*?(?=\\[nrtvf]|\s*(?:authorization|set-cookie|cookie)\s*[:=]|[<>]|$)"#,
            replacement: "$1[redacted]"
        ),
        RedactionPattern(
            expression: #"(?i)("(?:consumer_key|consumer_secret|access_token|token|application_password|password)"\s*:\s*")[^"]*(")"#,
            replacement: "$1[redacted]$2"
        ),
        RedactionPattern(
            expression: #"(?i)\b((?:consumer_key|consumer_secret|access_token|token|application_password|password)\s*[=:]\s*)[^&\s;'",<>\\]+"#,
            replacement: "$1[redacted]"
        ),
        RedactionPattern(
            expression: #"(?i)\b((?:session|wordpress_logged_in[\w-]*)\s*=\s*)[^&\s;'",<>\\]+"#,
            replacement: "$1[redacted]"
        )
    ]

    private static let readableBoundaryPatterns: [RedactionPattern] = [
        RedactionPattern(
            expression: #"(?i)([^\s<>,;:"'=])((?:authorization|set-cookie|cookie)\s*[:=])"#,
            replacement: "$1 $2"
        ),
        RedactionPattern(
            expression: #"(?i)([^A-Za-z_\s<>,;:"'=])((?:session|wordpress_logged_in[\w-]*)\s*=)"#,
            replacement: "$1 $2"
        )
    ]

    private func rawBodyErrorContext(from responseData: Data) -> RawBodyErrorContext? {
        guard let rootDictionary = jsonDictionary(from: responseData) else {
            return nil
        }

        if let rootError = rawBodyErrorContext(from: rootDictionary, fallbackProxyStatus: intValue(rootDictionary["status"])) {
            return rootError
        }

        let envelopeStatus = intValue(rootDictionary["status"])
        if let bodyDictionary = rootDictionary["body"] as? JSONDictionary {
            return rawBodyErrorContext(from: bodyDictionary, fallbackProxyStatus: envelopeStatus)
        }

        if let bodyString = rootDictionary["body"] as? String,
           let bodyData = bodyString.data(using: .utf8),
           let bodyDictionary = jsonDictionary(from: bodyData) {
            return rawBodyErrorContext(from: bodyDictionary, fallbackProxyStatus: envelopeStatus)
        }

        return nil
    }

    private func rawBodyErrorContext(from dictionary: JSONDictionary, fallbackProxyStatus: Int?) -> RawBodyErrorContext? {
        guard let data = dictionary["data"] as? JSONDictionary,
              let rawBody = data["raw_body"] as? String,
              rawBody.isEmpty == false else {
            return nil
        }

        return RawBodyErrorContext(
            errorCode: dictionary["error"] as? String ?? dictionary["code"] as? String,
            errorMessage: dictionary["message"] as? String,
            proxyStatus: intValue(data["status"]) ?? fallbackProxyStatus,
            rawBody: rawBody
        )
    }

    private func jsonDictionary(from data: Data) -> JSONDictionary? {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? JSONDictionary else {
            return nil
        }
        return dictionary
    }

    private func intValue(_ value: Any?) -> Int? {
        switch value {
        case let value as Int:
            return value
        case let value as NSNumber:
            return value.intValue
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }

    private func normalizedPath(for request: JetpackRequest) -> String {
        if let requestPath = pathWithoutHost(from: request.path) {
            return requestPath
        }

        let requestPath = String(request.path.drop(while: { $0 == "/" }))
        return request.wooApiVersion.path + requestPath
    }

    private func pathWithoutHost(from path: String) -> String? {
        guard let components = URLComponents(string: path),
              components.scheme != nil || components.host != nil else {
            return nil
        }

        let query = components.query.map { "?\($0)" } ?? ""
        return components.path + query
    }

    private func sanitizedSnippet(_ value: String) -> (value: String, truncated: Bool) {
        let sanitized = sanitize(value)
        let truncated = sanitized.count > maxSnippetLength
        return (String(sanitized.prefix(maxSnippetLength)), truncated)
    }

    private func sanitize(_ value: String) -> String {
        let readableValue = Self.readableBoundaryPatterns.reduce(singleLineReadableValue(value)) { partialResult, pattern in
            partialResult.replacingOccurrences(
                of: pattern.expression,
                with: pattern.replacement,
                options: .regularExpression
            )
        }

        return Self.redactionPatterns.reduce(readableValue) { partialResult, pattern in
            partialResult.replacingOccurrences(
                of: pattern.expression,
                with: pattern.replacement,
                options: .regularExpression
            )
        }.trimmingCharacters(in: .whitespaces)
    }

    private func singleLineReadableValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r\n", with: "\\n")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "\u{0B}", with: "\\v")
            .replacingOccurrences(of: "\u{0C}", with: "\\f")
            .replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
    }
}
