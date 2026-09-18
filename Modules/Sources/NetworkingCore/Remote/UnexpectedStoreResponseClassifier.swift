import Foundation

/// Classifies a merchant response that cannot be processed as REST JSON.
///
/// The classifier never returns response content.
public enum UnexpectedStoreResponseClassifier {
    public static func classify(responseData: Data,
                                request: Request,
                                statusCode: Int? = nil,
                                contentType: String? = nil) -> UnexpectedStoreResponseError? {
        guard request is JetpackRequest || request is RESTRequest ||
                (request as? UnauthenticatedRequest)?.isMerchantRESTRequest == true else {
            return nil
        }
        if request is JetpackRequest,
           let rawBodyError = JetpackTunnelRawBodyErrorLogger.rawBodyError(in: responseData) {
            return makeError(
                body: rawBodyError.data,
                statusCode: rawBodyError.statusCode ?? statusCode,
                contentType: nil
            )
        }

        return makeError(
            body: responseData,
            statusCode: statusCode,
            contentType: contentType
        )
    }

    /// Lets direct URLSession clients use the same safe classification without constructing a REST request.
    public static func classify(responseData: Data,
                                statusCode: Int?,
                                contentType: String? = nil,
                                expectsJSON: Bool = true) -> UnexpectedStoreResponseError? {
        makeError(
            body: responseData,
            statusCode: statusCode,
            contentType: contentType,
            expectsJSON: expectsJSON
        )
    }
}

private extension UnexpectedStoreResponseClassifier {
    static func makeError(body: Data,
                          statusCode: Int?,
                          contentType: String?,
                          expectsJSON: Bool = true) -> UnexpectedStoreResponseError? {
        let response = String(decoding: body, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard response.isEmpty == false || statusCode == 429 else {
            return nil
        }

        // 4xx keeps existing auth/validation handling. The status mapper owns
        // 401/403/404/426. The unexpected modal only handles 2xx non-JSON, 429, and 5xx HTML.
        if let statusCode, (400..<500).contains(statusCode), statusCode != 429 {
            return nil
        }

        // REST objects/arrays, including malformed JSON, keep their existing decoder/error path.
        // Valid JSON scalar values are also JSON, even when a string contains HTML.
        if response.hasPrefix("{") || response.hasPrefix("[") ||
            (try? JSONSerialization.jsonObject(with: body, options: .fragmentsAllowed)) != nil {
            return nil
        }
        let mediaType = contentType?.split(separator: ";", maxSplits: 1).first?
            .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isHTML = mediaType == "text/html" ||
            mediaType == "application/xhtml+xml" ||
            response.hasPrefix("<")
        let isServerError = statusCode.map { (500..<600).contains($0) } ?? false
        let isRateLimited = statusCode == 429
        let isSuccessfulResponse = statusCode.map { (200..<300).contains($0) } ?? true

        // Keep plain-text 4xx authentication and validation responses on their existing path.
        // A successful nonce response is plain text. Other successful REST responses must be JSON.
        guard isHTML || isRateLimited || isServerError || (expectsJSON && isSuccessfulResponse) else {
            return nil
        }

        return UnexpectedStoreResponseError()
    }
}
