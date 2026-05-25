import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AssistantURLPolicyTests {

    @Test(arguments: [
        "https://example.com",
        "http://example.com",
        "HTTPS://example.com"
    ])
    func test_allows_when_scheme_is_http_or_https_then_returns_true(_ string: String) throws {
        // Given
        let url = try #require(URL(string: string))

        // When
        let allowed = AssistantURLPolicy.allows(url)

        // Then
        #expect(allowed)
    }

    @Test(arguments: [
        "sms:+19001234567?body=YES",
        "tel:+1900",
        "mailto:foo@bar.com",
        "file:///etc/passwd",
        "javascript:alert(1)",
        "whatsapp://send?phone=1",
        "itms-apps://itunes.apple.com/app/idXXX"
    ])
    func test_allows_when_scheme_is_disallowed_then_returns_false(_ string: String) throws {
        // Given
        let url = try #require(URL(string: string))

        // When
        let allowed = AssistantURLPolicy.allows(url)

        // Then
        #expect(allowed == false)
    }

    @Test
    func test_allows_when_url_has_no_scheme_then_returns_false() throws {
        // Given
        let url = try #require(URL(string: "no-scheme", relativeTo: nil))

        // When
        let allowed = AssistantURLPolicy.allows(url)

        // Then
        #expect(allowed == false)
    }
}
