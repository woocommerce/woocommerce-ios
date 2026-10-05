import Foundation

enum UnexpectedResponseExcerpt {
    static func make(_ body: String) -> String? {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        let text: String
        if let json = try? JSONSerialization.jsonObject(with: Data(trimmed.utf8), options: .fragmentsAllowed) {
            guard let error = json as? [String: Any], let code = error["code"] as? String,
                  let message = error["message"] as? String else { return nil }
            text = "\(code) | \(visibleText(message))"
        } else {
            let stripped = replace(#"(?is)<!--.*?(?:-->|$)|<(script|style|noscript|template|svg|iframe|textarea|select)\b[^>]*>.*?(?:</\1\s*>|$)"#,
                                   in: trimmed, with: " ")
            // Do not include JSON appended to plugin/debug output, including malformed JSON.
            let visible = String(stripped.prefix { $0 != "{" && $0 != "[" })
            let title = capture(#"(?is)<title\b[^>]*>(.*?)</title\s*>"#, in: visible).map(visibleText) ?? ""
            let page = visibleText(replace(#"(?is)<head\b[^>]*>.*?(?:</head\s*>|(?=<body\b)|$)"#, in: visible, with: " "))
            text = title.isEmpty || page.hasPrefix(title) ? page : "\(title) | \(page)"
        }
        let cleaned = sanitize(text)
        guard !cleaned.isEmpty else { return nil }
        return cleaned.count > 300 ? String(cleaned.prefix(299)) + "…" : cleaned
    }

    static func sanitize(_ value: String) -> String {
        let patterns: [(String, String)] = [
            (#"(?i)\bBearer\s+[^\s,;]+"#, "Bearer [redacted]"),
            (#"(?i)\b(Set-Cookie|Cookie|Authorization):[^\r\n]+"#, "$1: [redacted]"),
            (#"\b[A-Za-z0-9]{4}(?: [A-Za-z0-9]{4}){5}\b"#, "[redacted]"),
            (#"(?i)(\b(?:consumer_key|consumer_secret|access_token|token|application_password|password|pwd)\b[\"']?\s*[:=]\s*)(?:\"[^\"]*\"|'[^']*'|[^\s&;,<>]+)"#,
             "$1[redacted]"),
            (#"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#, "[email]"),
            (#"\b(?:\d{1,3}\.){3}\d{1,3}\b"#, "[ip]"),
            (#"(?i)(?<![\da-f:])(?:[\da-f]{0,4}:){2,}[\da-f:.]*(?![\da-f:])"#, "[ip]")
        ]
        let redacted = patterns.reduce(value) { replace($1.0, in: $0, with: $1.1) }
        return replace(#"\s+"#, in: redacted, with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func visibleText(_ value: String) -> String {
        let visible = replace(#"(?is)<!--.*?(?:-->|$)|<(script|style|noscript|template|textarea)\b[^>]*>.*?(?:</\1\s*>|$)"#,
                              in: value, with: " ")
        return replace(#"(?s)<[^>]*>"#, in: visible, with: " ").strippedHTML
    }

    private static func replace(_ pattern: String, in value: String, with replacement: String) -> String {
        value.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
    }

    private static func capture(_ pattern: String, in value: String) -> String? {
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
              let range = Range(match.range(at: 1), in: value) else { return nil }
        return String(value[range])
    }
}
