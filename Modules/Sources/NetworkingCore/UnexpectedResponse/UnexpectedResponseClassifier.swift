import Foundation

/// Classification is separate from business-error presentation and never emits analytics.
enum UnexpectedResponseClassifier {
    static func classify(data: Data?, status: Int, contentType: String?) -> UnexpectedStoreResponseError.Kind? {
        if (500...599).contains(status) { return .unacceptableStatusCode }
        let body = data.flatMap { String(data: $0, encoding: .utf8) }?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let data, (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)) != nil { return nil }
        if (200...299).contains(status) { return .unexpectedContent }
        if status == 429 { return .unacceptableStatusCode }
        let mediaType = contentType?.split(separator: ";").first?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if body.hasPrefix("<") || (!body.isEmpty && ["text/html", "application/xhtml+xml"].contains(mediaType)) {
            return .unacceptableStatusCode
        }
        return nil
    }

    /// Only an attributed store body may override a tunnel/WordPress.com error.
    static func tunnelResponse(in data: Data, enclosingStatus: Int? = nil) -> (data: Data, status: Int)? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let proxyStatus = statusCode(object["status"]) ?? enclosingStatus
        if let payload = object["data"] as? [String: Any], let body = payload["raw_body"] as? String,
           !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let status = statusCode(payload["status"]) ?? proxyStatus, (100...599).contains(status) {
            return (Data(body.utf8), status)
        }
        if let body = object["body"] as? String { return tunnelResponse(in: Data(body.utf8), enclosingStatus: proxyStatus) }
        if let body = object["body"] as? [String: Any], let nested = try? JSONSerialization.data(withJSONObject: body) {
            return tunnelResponse(in: nested, enclosingStatus: proxyStatus)
        }
        return nil
    }

    private static func statusCode(_ value: Any?) -> Int? {
        (value as? Int) ?? (value as? String).flatMap(Int.init)
    }
}
