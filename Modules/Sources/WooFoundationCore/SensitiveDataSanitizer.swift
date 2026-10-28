import Foundation

public enum SensitiveDataSanitizer {
    public struct Options: OptionSet, Sendable {
        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public static let redactURLQueries = Self(rawValue: 1 << 0)
        public static let redactLongTokens = Self(rawValue: 1 << 1)
        public static let redactAuthenticationCodes = Self(rawValue: 1 << 2)
    }

    public static func sanitize(_ value: String, options: Options = []) -> String {
        let visibleValue = String(value.unicodeScalars.filter { scalar in
            switch scalar.properties.generalCategory {
            case .format, .surrogate:
                return false
            case .control:
                return [9, 10, 13].contains(scalar.value)
            default:
                return true
            }
        })
        var redacted = commonReplacements.reduce(visibleValue) { value, replacement in
            replace(replacement.pattern, in: value, with: replacement.value, options: replacement.options)
        }

        if options.contains(.redactAuthenticationCodes) {
            redacted = replace(#"\b[A-Za-z0-9]{4}(?: [A-Za-z0-9]{4}){5}\b"#, in: redacted, with: "[redacted]")
        }
        if options.contains(.redactURLQueries) {
            redacted = replace(#"\?[^\s=]+=\S*"#, in: redacted, with: "?[redacted]")
        }
        if options.contains(.redactLongTokens) {
            redacted = replace(#"[A-Za-z0-9_\-]{32,}"#, in: redacted, with: "[redacted]")
        }

        return replace(#"\s+"#, in: redacted, with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension SensitiveDataSanitizer {
    static let assignmentSecretKeys = #"consumer_key|application_password|password|pwd|cookies?|key|\w*secret|\w*token|\w*nonce|api[_ -]?key"#
    static let secretKeys = assignmentSecretKeys + #"|authorization"#
    static let commonReplacements: [(pattern: String, value: String, options: String.CompareOptions)] = [
        (#"(?i)\bBearer\s+[^\s,;]+"#, "Bearer [redacted]", .regularExpression),
        (#"(?i)\b(Cookie|Set-Cookie):\s*[^\r\n,]+"#, "$1: [redacted]", .regularExpression),
        (#"(?i)\b(Authorization):(?!\s*Bearer\b)\s*[^\r\n,]+"#, "$1: [redacted]", .regularExpression),
        (#"(?i)\b(authorization\s*=\s*)(?:\"[^\"]*\"|'[^']*'|[^\s&;,<>]+)"#, "$1[redacted]", .regularExpression),
        (#"(\"(?:\#(secretKeys))\"\s*:\s*\")[^\"]*(\")"#, "$1[redacted]$2", [.regularExpression, .caseInsensitive]),
        (#"\b((?:\#(assignmentSecretKeys))\s*[:=]\s*)(?:\"[^\"]*\"|'[^']*'|[^\s&;,<>]+)"#,
         "$1[redacted]", [.regularExpression, .caseInsensitive]),
        (#"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#, "[email]", .regularExpression),
        (#"\b(?:\d{1,3}\.){3}\d{1,3}\b"#, "[ip]", .regularExpression),
        (#"(?i)(?<![\da-f:])(?:[\da-f:.]*::[\da-f:.]*|(?:[\da-f]{1,4}:){7}[\da-f]{1,4})(?![\da-f:])"#, "[ip]", .regularExpression)
    ]

    static func replace(_ pattern: String,
                        in value: String,
                        with replacement: String,
                        options: String.CompareOptions = .regularExpression) -> String {
        value.replacingOccurrences(of: pattern, with: replacement, options: options)
    }
}
