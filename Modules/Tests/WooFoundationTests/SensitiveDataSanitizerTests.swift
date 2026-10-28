import Testing
@testable import WooFoundationCore

struct SensitiveDataSanitizerTests {
    @Test func test_sanitize_when_value_contains_common_sensitive_data_then_redacts_it() {
        // Given
        let value = """
        Authorization: Bearer private-token, token=private-value, "password":"private-password",
        admin@example.com, 203.0.113.7, 2001:db8::1, Sync\u{200B} error at 10:20:30
        """

        // When
        let result = SensitiveDataSanitizer.sanitize(value)

        // Then
        #expect(result == "Authorization: Bearer [redacted], token=[redacted], \"password\":\"[redacted]\", [email], [ip], [ip], Sync error at 10:20:30")
    }

    @Test func test_sanitize_when_context_specific_options_are_enabled_then_applies_them() {
        // Given
        let value = "URL https://example.com/path?order=private auth: abcd efgh ijkl mnop qrst uvwx token abcdefghijklmnopqrstuvwxyz123456"

        // When
        let result = SensitiveDataSanitizer.sanitize(
            value,
            options: [.redactURLQueries, .redactLongTokens, .redactAuthenticationCodes]
        )

        // Then
        #expect(result == "URL https://example.com/path?[redacted] auth: [redacted] token [redacted]")
    }

    @Test func test_sanitize_when_context_specific_options_are_disabled_then_preserves_diagnostic_values() {
        // Given
        let value = "URL https://example.com/path?order=123 body abcdefghijklmnopqrstuvwxyz123456"

        // When
        let result = SensitiveDataSanitizer.sanitize(value)

        // Then
        #expect(result == value)
    }
}
