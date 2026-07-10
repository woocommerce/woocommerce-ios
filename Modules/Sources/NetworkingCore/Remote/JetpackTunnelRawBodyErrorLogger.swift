import Foundation

protocol JetpackTunnelRawBodyErrorLogging {
    func logIfNeeded(responseData: Data?, request: Request, transportStatus: Int?)
}

struct JetpackTunnelRawBodyErrorLogger: JetpackTunnelRawBodyErrorLogging {
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

    private func buildMessage(responseData: Data, request: JetpackRequest, transportStatus: Int?) -> String? {
        guard let rawBodyError = rawBodyErrorContext(from: responseData) else {
            return nil
        }

        let snippet = sanitizedSnippet(rawBodyError.rawBody)
        let fields = [
            "method=\(request.method.rawValue.uppercased())",
            "path=\(sanitize(normalizedPath(for: request)))",
            transportStatus.map { "transport_status=\($0)" },
            rawBodyError.proxyStatus.map { "proxy_status=\($0)" },
            "error_code=\(sanitize(rawBodyError.errorCode))",
            "error_message=\(sanitize(rawBodyError.errorMessage))",
            "raw_body_truncated=\(snippet.truncated)",
            "raw_body_snippet=\(snippet.value)"
        ].compactMap { $0 }

        return "Jetpack Tunnel raw_body error: \(fields.joined(separator: ", "))"
    }
}

private extension JetpackTunnelRawBodyErrorLogger {
    struct RawBodyErrorResponse: Decodable {
        let payload: RawBodyErrorPayload
        let body: RawBodyErrorBody?

        init(from decoder: Decoder) throws {
            payload = try RawBodyErrorPayload(from: decoder)

            let container = try decoder.container(keyedBy: CodingKeys.self)
            body = try? container.decodeIfPresent(RawBodyErrorBody.self, forKey: .body)
        }

        private enum CodingKeys: String, CodingKey {
            case body
        }
    }

    struct RawBodyErrorPayload: Decodable {
        let error: String?
        let code: String?
        let message: String?
        let status: Int?
        let data: RawBodyErrorData?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            error = try? container.decodeIfPresent(String.self, forKey: .error)
            code = try? container.decodeIfPresent(String.self, forKey: .code)
            message = try? container.decodeIfPresent(String.self, forKey: .message)
            status = container.failsafeDecodeIfPresent(integerForKey: .status)
            data = try? container.decodeIfPresent(RawBodyErrorData.self, forKey: .data)
        }

        private enum CodingKeys: String, CodingKey {
            case error
            case code
            case message
            case status
            case data
        }
    }

    struct RawBodyErrorData: Decodable {
        let status: Int?
        let rawBody: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            status = container.failsafeDecodeIfPresent(integerForKey: .status)
            rawBody = try? container.decodeIfPresent(String.self, forKey: .rawBody)
        }

        private enum CodingKeys: String, CodingKey {
            case status
            case rawBody = "raw_body"
        }
    }

    enum RawBodyErrorBody: Decodable {
        case payload(RawBodyErrorPayload)
        case jsonString(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let payload = try? container.decode(RawBodyErrorPayload.self) {
                self = .payload(payload)
                return
            }

            if let jsonString = try? container.decode(String.self) {
                self = .jsonString(jsonString)
                return
            }

            throw DecodingError.typeMismatch(
                RawBodyErrorBody.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected object or stringified JSON body")
            )
        }

        var payload: RawBodyErrorPayload? {
            switch self {
            case .payload(let payload):
                return payload
            case .jsonString(let jsonString):
                guard let data = jsonString.data(using: .utf8) else {
                    return nil
                }
                return try? JSONDecoder().decode(RawBodyErrorPayload.self, from: data)
            }
        }
    }

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
            expression: #"(?i)\bBearer\s+[^\s,;]+"#,
            replacement: "Bearer [redacted]"
        ),
        RedactionPattern(
            expression: #"(?i)\b(Cookie|Set-Cookie):\s*[^\n\r,]+"#,
            replacement: "$1: [redacted]"
        ),
        RedactionPattern(
            expression: #"(?i)("(?:consumer_key|consumer_secret|access_token|token|application_password|password)"\s*:\s*")[^"]*(")"#,
            replacement: "$1[redacted]$2"
        ),
        RedactionPattern(
            expression: #"(?i)(^|[?&;\s])((?:consumer_key|consumer_secret|access_token|token|application_password|password)=)[^&;\s,"'}]+"#,
            replacement: "$1$2[redacted]"
        )
    ]

    private static let whitespacePattern = #"\s+"#

    private func rawBodyErrorContext(from responseData: Data) -> RawBodyErrorContext? {
        guard let response = try? JSONDecoder().decode(RawBodyErrorResponse.self, from: responseData) else {
            return nil
        }

        if let rootError = rawBodyErrorContext(from: response.payload, fallbackProxyStatus: response.payload.status) {
            return rootError
        }

        if let bodyPayload = response.body?.payload {
            return rawBodyErrorContext(from: bodyPayload, fallbackProxyStatus: response.payload.status)
        }

        return nil
    }

    private func rawBodyErrorContext(from payload: RawBodyErrorPayload, fallbackProxyStatus: Int?) -> RawBodyErrorContext? {
        guard let rawBody = payload.data?.rawBody,
              rawBody.contains(where: { $0.isWhitespace == false }) else {
            return nil
        }

        return RawBodyErrorContext(
            errorCode: payload.error ?? payload.code,
            errorMessage: payload.message,
            proxyStatus: payload.data?.status ?? fallbackProxyStatus,
            rawBody: rawBody
        )
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

    private func sanitize(_ value: String?) -> String {
        Self.redactionPatterns.reduce(value ?? "") { partialResult, pattern in
            partialResult.replacingOccurrences(
                of: pattern.expression,
                with: pattern.replacement,
                options: .regularExpression
            )
        }
        .replacingOccurrences(of: Self.whitespacePattern, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
