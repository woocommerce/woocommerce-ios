import Foundation
import CocoaLumberjackSwift

/// Shape helpers shared between the production REST client adaptor and the
/// module's unit tests. Kept out of the adaptor so the parsing logic stays
/// test-covered without pulling Networking / Jetpack dependencies into the
/// module.
public enum JetpackResponseParsing {

    /// Jetpack-tunneled responses come wrapped as `{"data":<inner>,...}`.
    /// Direct REST returns the naked WC response. Peel the envelope so
    /// downstream parsers see the same shape regardless of auth route.
    ///
    /// Guards against the WP error envelope `{"code","message","data":{...}}`
    /// which also has a `data` key but whose inner value is error metadata -
    /// peeling it would hand callers `{"status":404}` as if a tool returned
    /// a row. Error envelopes pass through unchanged so the higher layer
    /// surfaces them.
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

    /// Splits a tool path like `"wc/v3/orders"` or
    /// `"wc-analytics/reports/orders"` into the API-version prefix plus the
    /// sub-path beneath it. Unknown prefixes fall back to `.mark3` with the
    /// full path intact so a typo at least reaches a valid WC namespace
    /// that 404s loudly.
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

/// Mirror of Networking's `WooAPIVersion`. Duplicated to keep this module's
/// dependency surface small - Networking is a heavy target. The app-target
/// adaptor translates this into the real `WooAPIVersion` at the boundary.
public enum WCAPIVersion: String, Sendable, Equatable {
    case mark1 = "wc/v1"
    case mark2 = "wc/v2"
    case mark3 = "wc/v3"
    case mark4 = "wc/v4"
    case wcAnalytics = "wc-analytics"
}
