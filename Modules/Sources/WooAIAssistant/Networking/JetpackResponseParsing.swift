import Foundation
import CocoaLumberjackSwift

public enum JetpackResponseParsing {

    /// Leaves the WP error envelope `{"code","message","data":{...}}` untouched - peeling its `data`
    /// key would hand callers `{"status":404}` as if a tool returned a row.
    public static func unwrapJetpackEnvelope(_ data: Data) -> Data {
        guard !data.isEmpty else { return data }
        let json: [String: Any]
        do {
            guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return data
            }
            json = parsed
        } catch {
            DDLogError("⛔️ JetpackResponseParsing failed to parse envelope: \(error)")
            return data
        }
        if let code = json["code"] as? String, !code.isEmpty {
            return data
        }
        guard let inner = json["data"] else { return data }
        do {
            return try JSONSerialization.data(withJSONObject: inner, options: [.fragmentsAllowed])
        } catch {
            DDLogError("⛔️ JetpackResponseParsing failed to re-serialize inner payload: \(error)")
            return data
        }
    }

    public static func splitAPIVersion(from path: String) -> (apiVersion: WCAPIVersion, subpath: String) {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        if trimmed.hasPrefix("wc-analytics/") {
            return (.wcAnalytics, String(trimmed.dropFirst("wc-analytics/".count)))
        }
        let versioned: [(String, WCAPIVersion)] = [
            ("wc/v4/", .mark4),
            ("wc/v3/", .mark3),
            ("wc/v2/", .mark2),
            ("wc/v1/", .mark1)
        ]
        for (prefix, version) in versioned where trimmed.hasPrefix(prefix) {
            return (version, String(trimmed.dropFirst(prefix.count)))
        }
        return (.mark3, trimmed)
    }
}

/// Mirror of Networking's `WooAPIVersion`. Duplicated so this module avoids importing Networking.
public enum WCAPIVersion: String, Sendable, Equatable {
    case mark1 = "wc/v1"
    case mark2 = "wc/v2"
    case mark3 = "wc/v3"
    case mark4 = "wc/v4"
    case wcAnalytics = "wc-analytics"
}
