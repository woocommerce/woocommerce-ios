import Foundation

/// Shrinks WC REST entities before they hit `uiStructured.element` so HAL noise,
/// plugin meta_data, and base64-ish image arrays don't bloat the cache.
enum RESTPayloadPruning {
    private static let dropKeys: Set<String> = [
        "_links",
        "meta_data",
        "yoast_head",
        "yoast_head_json",
        "permalink",
        "product_permalink",
        "reviewer_avatar_urls"
    ]

    private static let freeTextKeys: Set<String> = [
        "description",
        "short_description"
    ]

    private static let maxFreeTextLength = 280

    static func prune(_ value: AnyCodableJSON) -> AnyCodableJSON {
        switch value {
        case .object(let dict):
            var out: [String: AnyCodableJSON] = [:]
            out.reserveCapacity(dict.count)
            for (key, raw) in dict where !dropKeys.contains(key) {
                if freeTextKeys.contains(key), case .string(let text) = raw {
                    out[key] = .string(shrinkFreeText(text))
                } else {
                    out[key] = prune(raw)
                }
            }
            return .object(out)
        case .array(let items):
            return .array(items.map(prune))
        default:
            return value
        }
    }

    private static func shrinkFreeText(_ value: String) -> String {
        var stripped = value
        while let range = stripped.range(of: "<[^>]+>", options: .regularExpression) {
            stripped.removeSubrange(range)
        }
        let normalized = stripped
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.count > maxFreeTextLength {
            return String(normalized.prefix(maxFreeTextLength)) + "..."
        }
        return normalized
    }
}
