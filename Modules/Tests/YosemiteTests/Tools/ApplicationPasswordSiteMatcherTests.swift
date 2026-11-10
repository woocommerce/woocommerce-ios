import Testing

@testable import Yosemite

struct ApplicationPasswordSiteMatcherTests {
    @Test func test_isWithinSite_when_candidate_is_the_same_URL_then_returns_true() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = Constants.siteURL

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(result)
    }

    @Test func test_isWithinSite_when_candidate_has_a_different_scheme_then_returns_true() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "http://site.example"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(result)
    }

    @Test func test_isWithinSite_when_candidate_has_a_port_then_returns_true() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://site.example:8443"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(result)
    }

    @Test func test_isWithinSite_when_candidate_has_a_path_then_returns_true() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://site.example/wp/wp-admin/authorize-application.php?app_name=woo"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(result)
    }

    @Test func test_isWithinSite_when_candidate_has_a_www_prefix_then_returns_true() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://www.site.example"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(result)
    }

    @Test func test_isWithinSite_when_site_address_has_a_www_prefix_then_returns_true() {
        // Given
        let siteURL = "https://www.site.example"
        let candidateURL = Constants.siteURL

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(result)
    }

    @Test func test_isWithinSite_when_candidate_has_an_uppercase_host_then_returns_true() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://WWW.Site.EXAMPLE"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(result)
    }

    @Test func test_isWithinSite_when_site_address_has_no_scheme_then_returns_true() {
        // Given
        let siteURL = "site.example"
        let candidateURL = Constants.siteURL

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(result)
    }

    @Test func test_isWithinSite_when_site_address_has_surrounding_whitespace_then_returns_true() {
        // Given
        let siteURL = "  https://site.example  "
        let candidateURL = Constants.siteURL

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(result)
    }

    @Test func test_isWithinSite_when_candidate_is_on_another_host_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://other.example"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_host_is_a_lookalike_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://site.example.evil.test"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_is_on_a_subdomain_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://shop.site.example"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_has_a_doubled_www_prefix_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://www.www.site.example"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_is_nil_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL: String? = nil

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_is_blank_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "   "

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_site_address_is_blank_then_returns_false() {
        // Given
        let siteURL = ""
        let candidateURL = Constants.siteURL

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_has_a_non_http_scheme_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "ftp://site.example"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_has_a_username_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://merchant@site.example"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_has_a_username_and_password_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://merchant:secret@site.example"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_user_info_hides_another_host_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://site.example@other.example"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_is_unparseable_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_has_an_invalid_host_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://site example"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_approvalSiteURL_when_approval_page_is_at_the_site_root_then_returns_the_site_address() {
        // Given
        let authorizationURL = "https://wp.site.example/wp-admin/authorize-application.php?app_name=woo&success_url=woocommerce://login"

        // When
        let result = ApplicationPasswordSiteMatcher.approvalSiteURL(for: authorizationURL)

        // Then
        #expect(result == "https://wp.site.example")
    }

    @Test func test_approvalSiteURL_when_approval_page_is_in_a_subfolder_install_then_keeps_the_subfolder() {
        // Given
        let authorizationURL = "https://site.example/wp/wp-admin/authorize-application.php"

        // When
        let result = ApplicationPasswordSiteMatcher.approvalSiteURL(for: authorizationURL)

        // Then
        #expect(result == "https://site.example/wp")
    }

    @Test func test_approvalSiteURL_when_admin_directory_is_renamed_then_drops_it() {
        // Given
        let authorizationURL = "https://site.example/private-admin/authorize-application.php"

        // When
        let result = ApplicationPasswordSiteMatcher.approvalSiteURL(for: authorizationURL)

        // Then
        #expect(result == Constants.siteURL)
    }

    @Test func test_approvalSiteURL_when_URL_is_not_the_approval_page_then_returns_nil() {
        // Given
        let authorizationURL = "https://site.example/ea-authorize/"

        // When
        let result = ApplicationPasswordSiteMatcher.approvalSiteURL(for: authorizationURL)

        // Then
        #expect(result == nil)
    }

    @Test func test_approvalSiteURL_when_authorization_URL_has_a_user_name_then_returns_nil() {
        // Given
        let authorizationURL = "https://x@site.example/wp-admin/authorize-application.php"

        // When
        let result = ApplicationPasswordSiteMatcher.approvalSiteURL(for: authorizationURL)

        // Then
        #expect(result == nil)
    }

    @Test func test_approvalSiteURL_when_approval_page_has_no_admin_directory_then_returns_nil() {
        // Given
        let authorizationURL = "https://site.example/authorize-application.php"

        // When
        let result = ApplicationPasswordSiteMatcher.approvalSiteURL(for: authorizationURL)

        // Then
        #expect(result == nil)
    }

    @Test func test_approvalSiteURL_when_URL_is_nil_then_returns_nil() {
        // Given
        let authorizationURL: String? = nil

        // When
        let result = ApplicationPasswordSiteMatcher.approvalSiteURL(for: authorizationURL)

        // Then
        #expect(result == nil)
    }

    @Test func test_isWithinSite_when_candidate_is_a_sibling_site_on_the_same_host_then_returns_false() {
        // Given
        let siteURL = "https://network.example/shop"
        let candidateURL = "https://network.example/evil"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_is_the_parent_of_the_site_path_then_returns_false() {
        // Given
        let siteURL = "https://network.example/shop"
        let candidateURL = "https://network.example"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_candidate_is_below_the_site_path_then_returns_true() {
        // Given
        let siteURL = "https://network.example/shop/"
        let candidateURL = "https://network.example/Shop/wp-admin/authorize-application.php"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(result)
    }

    @Test func test_isWithinSite_when_candidate_path_only_shares_a_prefix_then_returns_false() {
        // Given
        let siteURL = "https://network.example/shop"
        let candidateURL = "https://network.example/shopper"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isSameSiteAddress_when_address_differs_by_trailing_slash_and_www_then_returns_true() {
        // Given
        let siteURL = "https://site.example/shop"
        let candidateURL = "http://www.site.example/shop/"

        // When
        let result = ApplicationPasswordSiteMatcher.isSameSiteAddress(siteURL, candidateURL)

        // Then
        #expect(result)
    }

    @Test func test_isSameSiteAddress_when_candidate_has_a_deeper_path_then_returns_false() {
        // Given
        let siteURL = Constants.siteURL
        let candidateURL = "https://site.example/wp"

        // When
        let result = ApplicationPasswordSiteMatcher.isSameSiteAddress(siteURL, candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isApprovalPage_when_extra_path_follows_the_approval_page_then_returns_true() {
        // Given
        let url = "https://site.example/wp-admin/authorize-application.php/x"

        // When
        let result = ApplicationPasswordSiteMatcher.isApprovalPage(url)

        // Then
        #expect(result)
    }

    @Test func test_isApprovalPage_when_approval_page_name_is_encoded_then_returns_true() {
        // Given
        let url = "https://site.example/wp-admin/authorize-application%2Ephp"

        // When
        let result = ApplicationPasswordSiteMatcher.isApprovalPage(url)

        // Then
        #expect(result)
    }

    @Test func test_isApprovalPage_when_user_name_precedes_the_host_then_returns_true() {
        // Given
        let url = "https://x@site.example/wp-admin/authorize-application.php"

        // When
        let result = ApplicationPasswordSiteMatcher.isApprovalPage(url)

        // Then
        #expect(result)
    }

    @Test func test_isApprovalPage_when_user_name_and_password_precede_the_host_then_returns_true() {
        // Given
        let url = "https://x:y@site.example/wp-admin/authorize-application.php"

        // When
        let result = ApplicationPasswordSiteMatcher.isApprovalPage(url)

        // Then
        #expect(result)
    }

    @Test func test_isApprovalPage_when_URL_is_a_login_page_then_returns_false() {
        // Given
        let url = "https://site.example/wp-login.php?redirect_to=x"

        // When
        let result = ApplicationPasswordSiteMatcher.isApprovalPage(url)

        // Then
        #expect(!result)
    }

    @Test func test_approvalSiteURL_when_extra_path_follows_the_approval_page_then_returns_the_site_address() {
        // Given
        let authorizationURL = "https://site.example/wp-admin/authorize-application.php/x/y"

        // When
        let result = ApplicationPasswordSiteMatcher.approvalSiteURL(for: authorizationURL)

        // Then
        #expect(result == Constants.siteURL)
    }

    @Test func test_isApprovalPage_when_encoded_slash_precedes_the_approval_page_then_returns_true() {
        // Given
        let url = "https://site.example/wp-admin%2Fauthorize-application.php"

        // When
        let result = ApplicationPasswordSiteMatcher.isApprovalPage(url)

        // Then
        #expect(result)
    }

    @Test func test_isApprovalPage_when_encoded_slash_follows_the_approval_page_then_returns_true() {
        // Given
        let url = "https://site.example/wp-admin/authorize-application.php%2Fx"

        // When
        let result = ApplicationPasswordSiteMatcher.isApprovalPage(url)

        // Then
        #expect(result)
    }

    @Test func test_isWithinSite_when_encoded_dot_segments_leave_the_site_path_then_returns_false() {
        // Given
        let siteURL = "https://network.example/evil"
        let candidateURL = "https://network.example/evil%2F..%2Fshop/wp-admin/authorize-application.php"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_isWithinSite_when_backslash_leaves_the_site_path_then_returns_false() {
        // Given
        let siteURL = "https://network.example/evil"
        let candidateURL = "https://network.example/evil%5C..%5Cshop/wp-admin/authorize-application.php"

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    @Test func test_approvalSiteURL_when_encoded_slash_precedes_the_approval_page_then_returns_the_site_address() {
        // Given
        let authorizationURL = "https://site.example/shop/wp-admin%2Fauthorize-application.php"

        // When
        let result = ApplicationPasswordSiteMatcher.approvalSiteURL(for: authorizationURL)

        // Then
        #expect(result == "https://site.example/shop")
    }

    @Test func test_isApprovalPage_when_dot_segments_follow_the_approval_page_then_returns_true() {
        // Given
        let url = "https://site.example/wp-admin/authorize-application.php%2F..%2Fx"

        // When
        let result = ApplicationPasswordSiteMatcher.isApprovalPage(url)

        // Then
        #expect(result)
    }
}

private extension ApplicationPasswordSiteMatcherTests {
    enum Constants {
        static let siteURL = "https://site.example"
    }
}
