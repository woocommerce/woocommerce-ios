import Foundation
import Testing
@testable import NetworkingCore

struct WordPressLoginHTMLVerifierTests {
    @Test func test_eligible_wordpress_form_resolves_its_html_decoded_action() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let html = Self.loginForm(action: "../session?mode=login&amp;source=app")
        let documentURL = try url("https://example.com/account/final-login")

        // When
        let submissionURL = try endpoints.verifiedLoginFormSubmissionURL(in: html, documentURL: documentURL)

        // Then
        #expect(submissionURL?.absoluteString == "https://example.com/session?mode=login&source=app")
    }

    @Test func test_closed_comment_and_script_decoys_do_not_create_form_ambiguity() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let decoys = "<!--\(Self.loginForm(action: "https://attacker.example"))-->" +
            "<script>\(Self.loginForm(action: "https://attacker.example"))</script>"
        let html = decoys + Self.loginForm(action: "/authenticate")

        // When
        let submissionURL = try endpoints.verifiedLoginFormSubmissionURL(in: html, documentURL: url("https://example.com/login"))

        // Then
        #expect(submissionURL?.absoluteString == "https://example.com/authenticate")
    }

    @Test(arguments: invalidMarkup)
    func test_ineligible_or_structurally_unsafe_markup_is_rejected(_ html: String) throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))

        // When
        let submissionURL = try endpoints.verifiedLoginFormSubmissionURL(in: html, documentURL: url("https://example.com/login"))

        // Then
        #expect(submissionURL == nil)
    }

    @Test func test_unrelated_form_with_one_credential_marker_does_not_create_ambiguity() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let unrelatedForm = "<form method=\"post\"><input name=\"log\"></form>"
        let html = unrelatedForm + Self.loginForm(action: "/authenticate")

        // When
        let submissionURL = try endpoints.verifiedLoginFormSubmissionURL(in: html, documentURL: url("https://example.com/login"))

        // Then
        #expect(submissionURL?.absoluteString == "https://example.com/authenticate")
    }

    @Test func test_multiple_fully_eligible_wordpress_forms_are_rejected_as_ambiguous() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let html = Self.loginForm(action: "/first") + Self.loginForm(action: "/second")

        // When
        let submissionURL = try endpoints.verifiedLoginFormSubmissionURL(in: html, documentURL: url("https://example.com/login"))

        // Then
        #expect(submissionURL == nil)
    }

    @Test func test_quoted_attribute_content_and_html_entities_are_accepted() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let html = Self.loginForm(action: "/authenticate?mode=login&amp;source=app").replacingOccurrences(
            of: "method=\"POST\"",
            with: "method=\"POST\" data-note=\" name method action\""
        )

        // When
        let submissionURL = try endpoints.verifiedLoginFormSubmissionURL(in: html, documentURL: url("https://example.com/login"))

        // Then
        #expect(submissionURL?.absoluteString == "https://example.com/authenticate?mode=login&source=app")
    }

    @Test func test_authenticated_dashboard_requires_body_classes_and_dashboard_container() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let dashboard = "<body class=\"wp-core-ui INDEX-PHP wp-admin\"><div id=\"dashboard-widgets-wrap\"></div></body>"
        let missingClass = "<body class=\"wp-admin\"><div id=\"dashboard-widgets-wrap\"></div></body>"
        let scriptDecoy = "<body class=\"wp-admin index-php\"><script><div id=\"dashboard-widgets-wrap\"></div></script></body>"

        // When
        let isDashboard = endpoints.isAuthenticatedDashboardHTML(dashboard)

        // Then
        #expect(isDashboard)
        #expect(endpoints.isAuthenticatedDashboardHTML(missingClass) == false)
        #expect(endpoints.isAuthenticatedDashboardHTML(scriptDecoy) == false)
    }

    @Test func test_authenticated_dashboard_allows_ordinary_well_formed_forms() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let html = "<body class=\"wp-admin index-php\"><form role=\"search\" action=\"/search?name=log&amp;method=post\">" +
            "<input aria-label=\"Search\" name=\"s\"></form><div id=\"dashboard-widgets-wrap\"></div></body>"

        // When
        let isDashboard = endpoints.isAuthenticatedDashboardHTML(html)

        // Then
        #expect(isDashboard)
    }

    @Test func test_authenticated_dashboard_ignores_unrelated_unbalanced_form() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let html = "<body class=\"wp-admin index-php\"><form><input name=\"search\">" +
            "<div id=\"dashboard-widgets-wrap\"></div></body>"

        // When
        let isDashboard = endpoints.isAuthenticatedDashboardHTML(html)

        // Then
        #expect(isDashboard)
    }

    @Test func test_login_error_message_excludes_non_rendered_and_anchor_content() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let html = "<div id=\"login_error\"><strong>Error:</strong> Too many attempts. " +
            "<a href=\"/help\">Get help</a><script>hidden</script></div>"

        // When
        let message = endpoints.loginErrorMessage(in: html)

        // Then
        #expect(message == "Error: Too many attempts.")
    }
}

private extension WordPressLoginHTMLVerifierTests {
    static func loginForm(action: String?) -> String {
        let action = action.map { " action=\"\($0)\"" } ?? ""
        return "<form id=\"loginform\" name=\"loginform\" method=\"POST\"\(action)>" +
            "<input type=\"text\" name=\"log\" id=\"user_login\">" +
            "<input type=\"password\" name=\"pwd\" id=\"user_pass\"></form>"
    }

    static let invalidMarkup = [
        loginForm(action: nil).replacingOccurrences(of: " name=\"loginform\"", with: ""),
        loginForm(action: nil).replacingOccurrences(of: " id=\"loginform\"", with: ""),
        loginForm(action: nil).replacingOccurrences(of: "method=\"POST\"", with: "method=\"GET\""),
        loginForm(action: nil).replacingOccurrences(of: "id=\"user_login\"", with: "id=\"wrong\""),
        loginForm(action: nil).replacingOccurrences(of: "type=\"text\"", with: "type=\"email\""),
        loginForm(action: nil).replacingOccurrences(of: "id=\"user_pass\"", with: "id=\"wrong\""),
        loginForm(action: nil).replacingOccurrences(of: "type=\"password\"", with: "type=\"text\""),
        loginForm(action: nil).replacingOccurrences(of: "name=\"log\"", with: "name=\"log\" disabled"),
        loginForm(action: nil).replacingOccurrences(of: "name=\"pwd\"", with: "name=\"pwd\" form=\"other\""),
        loginForm(action: nil).replacingOccurrences(
            of: "<input type=\"password\"",
            with: "<input name=\"log\" id=\"decoy\" type=\"text\"><input type=\"password\""
        ),
        loginForm(action: nil).replacingOccurrences(of: "</form>", with: ""),
        "<script>\(loginForm(action: nil))",
        "<!--\(loginForm(action: nil))",
        "</form>\(loginForm(action: nil))",
        "<form id=\"loginform\" name=\"loginform\" method=\"post\"><form>" +
            "<input name=\"log\" id=\"user_login\" type=\"text\">" +
            "<input name=\"pwd\" id=\"user_pass\" type=\"password\"></form></form>"
    ]

    func url(_ value: String) throws -> URL {
        try #require(URL(string: value))
    }
}
