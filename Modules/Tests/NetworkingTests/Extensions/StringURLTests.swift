import Testing
@testable import NetworkingCore

struct StringURLTests {
    @Test func normalizedToHTTPS_when_scheme_is_http_replaces_only_the_scheme() {
        // Given
        let input = "http://example.com:8080/path?token=abc#fragment"

        // When
        let result = input.normalizedToHTTPS()

        // Then
        #expect(result == "https://example.com:8080/path?token=abc#fragment")
        #expect(input.requiresHTTPSNormalization)
    }

    @Test func normalizedToHTTPS_when_scheme_uses_mixed_case_normalizes_to_https() {
        // Given
        let input = "HtTp://example.com"

        // When
        let result = input.normalizedToHTTPS()

        // Then
        #expect(result == "https://example.com")
    }

    @Test func normalizedToHTTPS_when_scheme_is_already_https_leaves_url_unchanged() {
        // Given
        let input = "https://example.com/path"

        // When
        let result = input.normalizedToHTTPS()

        // Then
        #expect(result == input)
        #expect(!input.requiresHTTPSNormalization)
    }

    @Test func normalizedToHTTPS_when_value_is_not_an_http_url_leaves_value_unchanged() {
        // Given
        let input = "example.com/path"

        // When
        let result = input.normalizedToHTTPS()

        // Then
        #expect(result == input)
        #expect(!input.requiresHTTPSNormalization)
    }
}
