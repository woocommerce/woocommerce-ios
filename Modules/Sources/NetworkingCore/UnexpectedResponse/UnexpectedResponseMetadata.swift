import enum WooFoundationCore.SensitiveDataSanitizer

enum UnexpectedResponseMetadata {
    static func sanitize(_ value: String) -> String {
        SensitiveDataSanitizer.sanitize(value, options: .redactAuthenticationCodes)
    }
}
