import Foundation

enum UnexpectedResponseMetadata {
    static func sanitize(_ value: String) -> String {
        let secretFields = "consumer_key|consumer_secret|api_key|api_secret|access_token|refresh_token|token|" +
            "application_password|password|pwd|key|secret|authorization|cookie|cookies"
        let patterns: [(String, String)] = [
            (#"(?i)\bBearer\s+[^\s,;]+"#, "Bearer [redacted]"),
            (#"(?i)\b(Set-Cookie|Cookie|Authorization):[^\r\n]+"#, "$1: [redacted]"),
            (#"\b[A-Za-z0-9]{4}(?: [A-Za-z0-9]{4}){5}\b"#, "[redacted]"),
            (#"(?i)(\b(?:\#(secretFields))\b[\"']?\s*[:=]\s*)(?:\"[^\"]*\"|'[^']*'|[^\s&;,<>]+)"#,
             "$1[redacted]"),
            (#"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#, "[email]"),
            (#"\b(?:\d{1,3}\.){3}\d{1,3}\b"#, "[ip]"),
            (#"(?i)(?<![\da-f:])(?:[\da-f]{0,4}:){2,}[\da-f:.]*(?![\da-f:])"#, "[ip]")
        ]
        let redacted = patterns.reduce(value) { replace($1.0, in: $0, with: $1.1) }
        return replace(#"\s+"#, in: redacted, with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func replace(_ pattern: String, in value: String, with replacement: String) -> String {
        value.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
    }
}
